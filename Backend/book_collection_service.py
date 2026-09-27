import asyncio
from datetime import datetime, date
import os

from dotenv import load_dotenv

import standardmedia
import cache_lock_logic
import datacleaning
# --------------------------------------------------------------------------------
# Media information
# --------------------------------------------------------------------------------

(
    title_key,
    description_key,
    overall_rating_key,
    id_key,
    image_key,
    api_review_count_key,
    genres_key,
    release_date_key,
    creator_key,
    media_length_key,
    season_count_key,
) = standardmedia.getStandardMediaKeys()

book_id_identifier, movie_id_identifier, tv_id_identifier = (
    standardmedia.getStandardMediaIdentifiers()
)


media_invalid_str_key, media_invalid_int_key = standardmedia.getInvalidMediaValues()
lang_used = 'en'
GETTING_OG = False

load_dotenv()

# --------------------------------------------------------------------------------
# API information
# --------------------------------------------------------------------------------
OpenLibrary_cover_base_url = "https://covers.openlibrary.org/b/isbn/"
open_lib_api_url = "https://openlibrary.org"
open_lib_max_request_amount = 20

max_number_of_pages = 10
isbndb_max_request_amount = 50
isbndb_api_url = "https://api2.isbndb.com"
ISBNDB_API_KEY = os.getenv("ISBNDB_API_KEY")
ISBNdb_headers = {
    "Authorization": ISBNDB_API_KEY,
}

# -----------------------------------------------------------------------------------
# httpx information
# -----------------------------------------------------------------------------------
from httpx_logic import httpx_controller_client, sendAsyncHttpRequestGet


def hourCalculator(minues: float) -> int:
    return int(minues * 60 * 60)


def minuteCalculator(minutes: float) -> int:
    return int(minutes * 60)

# --------------------------------------------------------------------------------
# functional code 
# --------------------------------------------------------------------------------

async def getAllISBNs(uncleaned_book: dict) -> list:
    """
    collects all the isbns connected to this edition of the uncleaned_book
    """
    isbns = [uncleaned_book.get('isbn'), uncleaned_book.get('isbn10'), uncleaned_book.get('isbn13')]
    return isbns

# ===========================================================
# Book date cleaning logic 
# ===========================================================


async def getDateFromUncleanedBook(uncleaned_book) -> dict:
    date = {

        'year': float('inf'),
        'month': float('inf'),
        'day': float('inf')
    }
    unprocessed_date = uncleaned_book.get('date_published', '')

    split_date = unprocessed_date.split('-')
    if split_date[0] == '':
        return date

    if len(split_date) >= 1:
        date['year'] = int(split_date[0])

    if len(split_date) >= 2:
        date['month'] = int(split_date[1])

    if len(split_date) >= 3:
        date['day'] = int(split_date[2])
    
    return date


async def publishedEarlier(uncleaned_book_1, uncleaned_book_2):
    """
    Returns True if the first uncleaned book was published earlier than the second uncleaned book.
    False otherwise
    """
    date_1 = await getDateFromUncleanedBook(uncleaned_book_1)
    date_2 = await getDateFromUncleanedBook(uncleaned_book_2)

    if date_1['year'] < date_2['year']:
        return True
    
    if date_1['year'] > date_2['year']:
        return False
    
    if date_1['month'] < date_2['month']:
        return True
    
    if date_1['month'] > date_2['month']:
        return False
    
    if date_1['day'] < date_2['day']:
        return True
    
    if date_1['day'] > date_2['day']:
        return False
    
    # both books have the same release year, month, and day. Thus we can assume the first uncleaned book was release first.
    return True


# ===========================================================
# Book filtering logic (finding original)
# ===========================================================

def stripTextForBooks(text: str) -> str:
    """
    standardizes and strips the given text to make book standard.
    returns a string of the of the words in the text in a sorted order after cleaning.
    """
    # for now just removing new lines and extra spaces, but can add more as needed
    text = text.replace("\n", " ")
    text = text.replace('&', ' and ')
    text = text.replace("'", '')
    text = text.replace('.', ' ')
    text = text.lower()
    word_list = text.split()
    word_list.sort()

    word_str = " ".join(word_list)
    
    return word_str

def getStandardizedTitleAuthor(uncleaned_book: dict)-> str:
    title = stripTextForBooks(uncleaned_book['title'])
    author = stripTextForBooks(uncleaned_book['author'])

    result = ' - '.join([title, author])
    return result

async def checkBookAlreadyFound(found_isbns: set, uncleaned_book: dict) -> bool:
    """
    Checks if any of the isbns connected to this edition of the uncleaned_book are already contained in the found isbns.
    """
    book_isbns = await getAllISBNs(uncleaned_book=uncleaned_book)

    for book_isbn in book_isbns:
        if book_isbn in found_isbns:
            return True

    return False


async def getOriginalBookThroughISBN(uncleaned_book: dict) -> tuple:
    """
    Collects ther original version of the given book. 
    Returns a tuple of form:
    (Uncleaned Original Book, set of the isbns that relate to the same book)
    """
    # adding the inital isbns to the found set.
    # visited isbns
    start_isbns = await getAllISBNs(uncleaned_book=uncleaned_book)
    found_isbns = set(start_isbns)
    stack = [start_isbns[0]] 

    # marking dummy original book
    original_book = {
        title_key: media_invalid_str_key,
        'date_published': '9000'
    }  

    condition = uncleaned_book['title'].lower() == 'demon copperhead'

    if condition:
        print('=-='*60)
        print(f'STARTING ISBN: {uncleaned_book['isbn']}')
    # print('='*60)

    # DFS
    while stack:
        # collecting current book
        curr_isbn = stack.pop()
        # print(f'curr_isbn: {curr_isbn}')
        curr_book = await getBookUsingISBN(isbn=curr_isbn, lang=lang_used)

        curr_book_published_earlier = await publishedEarlier(curr_book, original_book)

        if curr_book_published_earlier:
            original_book = curr_book

        # searching through "neighboring" isbns which refer to the same book.
        neighbor_books = curr_book.get('other_isbns', [])

        for neighbor_book in neighbor_books:
        
            other_book = await getBookUsingISBN(neighbor_book['isbn'], lang=lang_used) 

            if 'status' in other_book and other_book['status'] == 'error':
                continue

            # if invalid neighbor skip
            already_found = await checkBookAlreadyFound(found_isbns=found_isbns, uncleaned_book=other_book)
            if not other_book or already_found:
                # adding all isbns to the found list incase only one of them was previously stored.
                other_books_isbns = await getAllISBNs(uncleaned_book=other_book)
                found_isbns.update(other_books_isbns)
                continue 

            # marking the nieghbor book as visited
            other_books_isbns = await getAllISBNs(uncleaned_book=other_book)
            found_isbns.update(other_books_isbns)
            stack.append(other_books_isbns[0])  


    # print(f'getOriginalBook: oldiest book found date: {original_book['date_published']}')
    if condition:
        print(f'found_isbns: {found_isbns}')
        print('=-='*60)

    return (original_book, found_isbns)


async def getOriginalBooks(uncleaned_book_list: list) -> tuple:
    found_isbns = set()

    # if ignoring 
    if not GETTING_OG:
        for uncleaned_book in uncleaned_book_list:
            isbns = await getAllISBNs(uncleaned_book=uncleaned_book)
            found_isbns.update(isbns)

        return uncleaned_book_list, found_isbns
    
    
    
    found_title_authors = {}

    for uncleaned_book in uncleaned_book_list:
        curr_isbn = uncleaned_book['isbn']
        title_author = getStandardizedTitleAuthor(uncleaned_book=uncleaned_book)


        already_found = False
        # if isbn already found 
        if curr_isbn in found_isbns:
            curr_isbns = getAllISBNs(uncleaned_book=uncleaned_book)
            found_isbns.update(curr_isbns)

            already_found = True
        
        if title_author in found_title_authors:
            pass
        


    


# ===========================================================
# Helper method for books logic
# ===========================================================

async def getBookUsingISBNCached(isbn: str, lang: str):
    """
    collects the book connected to the given isbn
    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, CALL WITH cache_lock_logic FOR BEST EFFICIENCY.
    """
    try:
        response_data = await sendAsyncHttpRequestGet(
            httpx_controller_client,
            f"{isbndb_api_url}/book/{isbn}",
            params=None,
            headers=ISBNdb_headers,
        )

        if "book" not in response_data or not response_data["book"]:
            raise Exception("ERRORS AHHH NO BOOK WHAT HAPPENED AHHHH")

        return response_data['book']
    except Exception as e:
        return {"status": "error", "message": f"{e}"}


ISBN_SEARCH_CACHE = cache_lock_logic.CACHE_LRU(maxsize=1000)
ISBN_SEARCH_LOCK = cache_lock_logic.LOCK(asyncio.Lock)

async def getBookUsingISBN(isbn: str, lang: str):
    """
    collects the book connected to the given isbn by calling the cached version
    """
    args = (isbn, lang)
    key = (isbn, lang)

    result = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=ISBN_SEARCH_CACHE,
        LOCK=ISBN_SEARCH_LOCK,
        function=getBookUsingISBNCached
    )
    
    return result









# ===========================================================
# Book collection logic
# ===========================================================

async def getBookVIASearchCached(
    title: str, request_amount: int, lang: str = "en"
) -> list:
    """
    searches for books using the given title in the Google Play API and returns a list of cleaned book data in our standard format that fit the search criteria. If no books are found, returns an empty list.


    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, PLEASE CALL WITH cache_lock_logic.cacheLockLogicTTL TO ENSURE PROPER EFFICIENCY AND FUNCTIONALITY
    """
    # clean input for generality
    title = datacleaning.cleanUserInput(title)

    page = 1
    result = []
    found_isbns = set()
    while len(result) < request_amount:
        data = await sendAsyncHttpRequestGet(
            httpx_controller_client,
            f"{isbndb_api_url}/books/{title}",
            params={"page": page, "pageSize": isbndb_max_request_amount},
            headers=ISBNdb_headers,
        )

        # no results
        if ("books" not in data) or (not data["books"]):
            break

        # checking each book in results
        result_temp = []
        for book in data["books"]:
            # if original version of book has already been found
            if book['isbn'] in found_isbns:
                print(f'already found book: {book['title']}')
                continue

            og_books, book_found_isbns = await getOriginalBooks(uncleaned_book_list=[book])
            og_book = og_books[0]

            # if no original book exists. TODO: miight be graduidice 
            if og_book[title_key] == media_invalid_str_key:
                continue
            
            found_isbns.update(book_found_isbns)

            # cleaning the book to fit our standard format
            cleaned_book = datacleaning.cleanBookDataISBNdb(book=og_book, lang=lang)

            # if the book has an invalid key, continue to next book
            if not datacleaning.checkValidBook(cleaned_book):
                continue

            result_temp.append(cleaned_book)
            # found_isbns.update(book_found_isbns)
        # result_temp = SimplyfySearchList(result_temp)
        result.extend(result_temp)
        # if found enough results
        if len(result) >= request_amount:
            break

        total = data.get("total", 0)
        max_pages = total // isbndb_max_request_amount

        if page > max_pages or page > max_number_of_pages:
            break

        page += 1

    # print(f'found isbns: {found_isbns}')
    

    for book in result:
        print(f'isbn: {book[id_key]}')
    print('=-='*60)
    return result[:request_amount]



BOOK_SEARCH_CACHE_TTL = cache_lock_logic.CACHE_TTL(maxsize=10000, ttl=hourCalculator(3))
BOOK_SEARCH_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getBookUsingSearch(title: str, request_amount: int, lang: str = "en") -> list:
    args = (title, request_amount, lang)
    key = (title, request_amount, lang)

    result = await cache_lock_logic.cacheLockLogicTTL(
        args=args,
        key=key,
        CACHE=BOOK_SEARCH_CACHE_TTL,
        LOCK=BOOK_SEARCH_LOCK,
        function=getBookVIASearchCached
    )   
    return result



async def getBookUsingID(book_id: str, lang: str = 'en') -> dict:
    # Getting Book using ISBN
    isbn = book_id[1:]

    uncleaned_book = await getBookUsingISBN(isbn=isbn, lang=lang)
 
    # collecting the original book
    if GETTING_OG:
        og_uncleaned_book, found_isbns = await getOriginalBooks(uncleaned_book_list=[uncleaned_book])
        og_uncleaned_book = og_uncleaned_book[0]
    else:
        og_uncleaned_book = uncleaned_book
        found_isbns = await getAllISBNs(uncleaned_book=uncleaned_book)



    
    # cleaning original book
    # print('='*60)
    # print(f'getBookUsingID: found_isbns: {found_isbns}')
    
    cleaned_book = datacleaning.cleanBookDataISBNdb(og_uncleaned_book, lang=lang)
    # print(f'chosen book: {cleaned_book}')
    # print('='*60)


    # print(f'getBookUsingID: cleaned_book: {cleaned_book}')
    return cleaned_book