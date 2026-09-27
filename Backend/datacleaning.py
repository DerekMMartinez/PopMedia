# from transformers import pipeline
import standardmedia
from fastapi import FastAPI

app = FastAPI()


"""
Data cleaning file


Converts given media (dictionaries) into dictionary of form:

    - title: str (title of the media)
    - description: str (description of the media)
    - overall_rating: float (rating of the media)
    - id: str (unique identifier of structure:  b<isbn> for books, m<int> for movies, t<int> for tv shows)
    - image: str (url to image of the media)
    - api_review_count: int (number of reviews from the API)
    - genres: list (list of genres the media belongs to) 

if any of the fields are missing from the original data, they will be filled with default values:
    - for string fields: 'N/A'
    - for int/float fields: -1.0
"""

# TODO: install transformers (jai)

# -----------------------------------------------------------------------------------
# media information
# -----------------------------------------------------------------------------------
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

(
    review_uid_key,
    review_username_key,
    review_media_id_key,
    review_rating_key,
    review_text_key,
    review_visibility_key,
    review_finished_on_key,
    review_spoiler_key,
) = standardmedia.getStandardReviewKeys()

tmdb_poster_base_url = "https://image.tmdb.org/t/p/w500"
open_lib_poster_url = "https://covers.openlibrary.org/b/isbn"
tmdb_logo_base_url = "https://image.tmdb.org/t/p/w200"

# -----------------------------------------------------------------------------------
# genre mapping information
# -----------------------------------------------------------------------------------
# Genre mappings key: genre id, value: genre name
TMDB_movie_genre_map = {
    28: "Action",
    12: "Adventure",
    16: "Animation",
    35: "Comedy",
    80: "Crime",
    99: "Documentary",
    18: "Drama",
    10751: "Family",
    14: "Fantasy",
    36: "History",
    27: "Horror",
    10402: "Music",
    9648: "Mystery",
    10749: "Romance",
    878: "Science Fiction",
    10770: "TV Movie",
    53: "Thriller",
    10752: "War",
    37: "Western",
}

# Genre mappings key: genre id, value: genre name
TMDB_tv_genre_map = {
    10759: "Action & Adventure",
    16: "Animation",
    35: "Comedy",
    80: "Crime",
    99: "Documentary",
    18: "Drama",
    10751: "Family",
    10762: "Kids",
    9648: "Mystery",
    10763: "News",
    10764: "Reality",
    10765: "Sci-Fi & Fantasy",
    10766: "Soap",
    10767: "Talk",
    10768: "War & Politics",
    37: "Western",
}


GP_book_genre_list = [
    "Fiction",
    "Nonfiction",
    "Mystery",
    "Science Fiction",
    "Fantasy",
    "Romance",
    "Thriller",
    "Horror",
    "Biography",
    "History",
    "Science",
    "Self-Help",
    "Health",
    "Travel",
    "Children's",
    "Young Adult",
    "Religion",
    "Spirituality",
    "Comics",
    "Graphic Novels",
]


# funkopop toe man
lowercase_english_alphabet = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
]

"""
Mapping from API genres to our standard genres. If an API genre maps to multiple standard genres, it will be listed as a list of genres.

listed by alphabetical order

CUURENT STANDARD GENRES:
- action
- adventure
- animation
- art
- biography
- business
- children
- comedy
- documentary
- drama
- education
- family
- fantasy
- fiction
- graphic novels
- health
- history
- horror
- musical
- mystery
- philosophy
- poetry
- politics
- reality
- religion
- romance
- science
- science fiction
- self-help
- social
- sports
- supernatural
- technology
- thriller
- war
- young adult
"""
# "dystopian": ["Science Fiction"], # TODO: ?
api_genre_to_standard_genre_map = {
    "action": ["action"],
    "action & adventure": ["action", "adventure"],
    "adventure": ["adventure"],
    "animation": ["animation"],
    "art": ["art"],
    "autobiography": ["biography"],
    "ballet": ["art", "sports"],  # both bc it is
    "baseball": ["sports"],
    "biography": ["biography"],
    "biography & autobiography": ["biography"],  # TODO: anything else?
    "biography & memoir": ["biography"],
    "business": ["business"],
    "business & economics": [
        "business"
    ],  # TODO: should economics be economics or business?
    "children": ["children"],
    "children's books": ["children"],
    "comedy": ["comedy"],
    "computers": ["technology"],
    "contemporary romance": ["romance"],
    "crime": ["mystery"],
    "detective": ["mystery"],
    "documentary": ["documentary"],
    "drama": ["drama"],
    "economics": ["business"],
    "education": ["education"],
    "engineering": ["technology"],  # todo is engineering technology or engineering?
    "epic": ["fantasy"],
    "epic fantasy": ["fantasy"],
    "ethics": ["philosophy"],
    "family": ["family"],
    "fantasy": ["fantasy"],
    "fantasy fiction": ["fantasy", "fiction"],
    "fiction": ["fiction"],
    "finance": ["business"],
    "fitness": ["health"],
    "football": ["sports"],
    "general fiction": ["fiction"],
    "ghost": ["horror"],
    "government": ["politics"],
    "graphic novel": ["graphic novels"],
    "health": ["health"],
    "historical": ["history"],
    "history": ["history"],
    "hockey": ["sports"],
    "horror": ["horror"],
    "juvenile fiction": ["children"],
    "kids": ["children"],
    "law": ["politics"],  # TODO: politics or law?
    "literary fiction": ["fiction"],
    "machine learning": ["technology"],
    "mathematics": ["science"],
    "medicine": ["health"],
    "memoir": ["biography"],
    "music": ["art"],
    "musical": ["musical"],
    "mystery": ["mystery"],
    "nature": ["science"],  # TODO: science? or nature?
    "paranormal": ["supernatural"],
    "philosophy": ["philosophy"],
    "physics": ["science"],
    "poetry": ["poetry"],
    "politics": ["politics"],
    "programming": ["technology"],
    "psychological thriller": ["thriller"],
    "reality": ["reality"],
    "religion": ["religion"],
    "romcom": ["romance", "comedy"],
    "romance": ["romance"],
    "romantic": ["romance"],
    "romantic comedy": ["romance", "comedy"],
    "sci-fi": ["science fiction"],
    "sci-fi & fantasy": ["science fiction", "fantasy"],
    "science": ["science"],
    "science fiction": ["science fiction"],
    "scifi": ["science fiction"],
    "self help": ["self-help"],
    "self improvement": ["self-help"],
    "self-help": ["self-help"],
    "soap": ["drama"],
    "social science": ["social", "science"],
    "software": ["technology"],
    "space opera": ["science fiction"],
    "spirituality": ["religion"],
    "sports": ["sports"],
    "supernatural": ["supernatural"],
    "suspense": ["thriller"],
    "textbook": ["education"],
    "theology": ["religion"],
    "thriller": ["thriller"],
    "urban fantasy": ["fantasy"],
    "war": ["war"],
    "war & politics": ["war", "politics"],
    "war and politics": ["war", "politics"],
    "ya fiction": ["young adult"],
    "young adult": ["young adult"],
}


# ------------------------------------------------------------------------------------
# Hate speech detection info
# ------------------------------------------------------------------------------------
hate_speech_threshold = 0.75

# hate_classifier = pipeline(
#     "text-classification",
#     model="Hate-speech-CNERG/dehatebert-mono-english"
# )

# -----------------------------------------------------------------------------------
# Mysc methods
# -----------------------------------------------------------------------------------


def validateUserInput(user_input: str) -> str:
    """
    Checks if the given string is a valid given our rules.


    Empty string is returned if:
    if the string contains hate speech
    if the string is just white space after cleaning


    Otherwise cleaned string is returned
    """

    cleaned_input = cleanUserInput(user_input)
    if checkEmptyString(cleaned_input):
        return ""

    return cleaned_input


def getKeys():
    """
    returns a dictionary mapping the standard keys to their corresponding values in the media dictionaries
    keys:

    title
    description
    overall_rating
    release_date
    id
    image
    api_review_count
    genres
    """
    return {
        "title": title_key,
        "description": description_key,
        "overall_rating": overall_rating_key,
        "release_date": release_date_key,
        "id": id_key,
        "image": image_key,
        "api_review_count": api_review_count_key,
        "genres": genres_key,
        "release_date": release_date_key,
    }


def isValidID(key: str):
    """
    Checks if the given key string is a valid key,

    A key is valid if it consists only of numbers and is not empty.

    returns True if the key is valid
    False otherwise
    """
    if checkEmptyString(key):
        return False

    for char in key:
        if not char.isdigit():
            return False

    return True


def checkValidBook(book: dict) -> bool:

    if book[id_key] == "N/A":
        return False

    # if book[overall_rating_key] == media_invalid_int_key:
    #     # print(f'INVALID RATING: {media[overall_rating_key]}')
    #     return False

    if (checkEmptyString(book[description_key])) or (
        book[description_key] == media_invalid_str_key
    ):
        # print(f'INVALID DESC: {media[description_key]}')
        return False

    if book[image_key] == media_invalid_str_key:
        # print(f'INVALID IMAGE: {media[image_key]}')
        return False

    if book[creator_key] == media_invalid_str_key:
        return False

    if not book[genres_key]:
        return False

    return True


def checkValidMovie(movie: dict) -> bool:
    """
    Checks if the given media is valid,

    If media is valid True is returned

    Media is invalid and False is returned if any of the following is present:
        - id: is empty or contains non integer values
        - description: is empty or the default value given
        - overall_rating: is -1
    """

    # ignoring the first index as it would be the identifier
    if not isValidID(movie[id_key][1:]):
        # print(f'INVALID ID: {media[id_key]}')
        return False

    if (checkEmptyString(movie[description_key])) or (
        movie[description_key] == media_invalid_str_key
    ):
        # print(f'INVALID DESC: {media[description_key]}')
        return False

    if movie[overall_rating_key] == media_invalid_int_key:
        # print(f'INVALID RATING: {media[overall_rating_key]}')
        return False

    if movie[image_key] == media_invalid_str_key:
        # print(f'INVALID IMAGE: {media[image_key]}')
        return False

    # TODO: temp fix for now, but need to find creators better.
    if movie[creator_key] == media_invalid_str_key:
        return False

    if not movie[genres_key]:
        return False

    return True


def checkValidTv(tv: dict) -> bool:
    """
    Checks if the given media is valid,

    If media is valid True is returned

    Media is invalid and False is returned if any of the following is present:
        - id: is empty or contains non integer values
        - description: is empty or the default value given
        - overall_rating: is -1
    """

    # ignoring the first index as it would be the identifier
    if not isValidID(tv[id_key][1:]):
        # print(f'INVALID ID: {media[id_key]}')
        return False

    if (checkEmptyString(tv[description_key])) or (
        tv[description_key] == media_invalid_str_key
    ):
        # print(f'INVALID DESC: {media[description_key]}')
        return False

    if tv[overall_rating_key] == media_invalid_int_key:
        # print(f'INVALID RATING: {media[overall_rating_key]}')
        return False

    if tv[image_key] == media_invalid_str_key:
        # print(f'INVALID IMAGE: {media[image_key]}')
        return False

    if not tv[genres_key]:
        return False

    # # TODO: temp fix for now, but need to find creators better.
    # if tv[creator_key] == media_invalid_str_key and tv[id_key][0] != 't':
    #     return False

    return True


def roundOverallRating(rating: float) -> float:
    """
    Rounds the given overall rating to the nearest 0.5

    returns the rounded rating
    """
    return round(rating * 2) / 2


import markdown
from bs4 import BeautifulSoup


def removeMarkdown(md_text: str) -> str:
    # Convert markdown to HTML
    html = markdown.markdown(md_text)

    # Strip HTML tags
    soup = BeautifulSoup(html, "html.parser")
    text = soup.get_text()

    return text.strip()


# -----------------------------------------------------------------------------------
# Cleaning methods
# -----------------------------------------------------------------------------------
"""
Clean Genres to fit our standard genre list.
TODO:
"""


def cleanGenres(genres: list):
    result = set()
    for genre in genres:
        lower_genre = genre.lower()
        if lower_genre in api_genre_to_standard_genre_map:
            result.update(api_genre_to_standard_genre_map[lower_genre])
        else:
            # print('------------------------------NOTICE-----------------------------------')
            # print(f"Genre '{genre}' not found in mapping, adding as is.")
            # print('------------------------------NOTICE-----------------------------------')
            result.add(lower_genre)

    return list(result)


def cleanUserInput(user_input: str):
    """
    Cleans the input string,
    Completes the following:

    - sets the inut to lowercase
    - Removes '\n' from anywhere in the string.

    returns cleaned input. TODO: add more cleaning steps as needed
    """
    # lowercasing the input for insensitive comparisons
    user_input = user_input.lower()
    # removing \n
    user_input = user_input.replace("\n", "")

    return user_input


"""
checks the input string for hate speech, 
returns true if there is substantial evidence of hate speech
false otherwise
"""
# def containsHateSpeech(user_input: str) -> bool:
#     result = hate_classifier(user_input)[0]
#     return result['label'] == 'HATE' and result['score'] > hate_speech_threshold


def checkEmptyString(s: str):
    """
    Checks if the given string is empty or only contains whitespace
    returns True if empty or only whitespace, False otherwise
    """
    return s is None or s.strip() == ""


def checkContainsSpoilers(review_text: str) -> bool:
    """
    Checks if the given review text contains spoilers by looking for common spoiler keywords.

    returns True if spoilers are likely present, False otherwise
    """
    spoiler_keywords = ["spoiler", "spoil"]
    allowed_keywords = ["spoiler-free", "spoiler free"]
    review_text_lower = review_text.lower()
    for keyword in spoiler_keywords:
        if (
            (keyword in review_text_lower)
            and allowed_keywords[0] not in review_text_lower
            and allowed_keywords[1] not in review_text_lower
        ):
            return True
    return False


# ---------------------------------------------------------------------------------------------------
# media cleaning methods
# ---------------------------------------------------------------------------------------------------


def cleanBookDataGP(book: dict):
    """
    Assumes the given dictionary is a book, and cleans it to fit the standard described at the top of the file.
    if the given book has an invalid id then it will return an empty media dictionary with default values. (id value will be 'N/A')
    """
    cleaned_book = standardmedia.getStandardEmptyMedia()

    # print('---------------------------------------------')
    # print(f'Cleaning book data: {book}')
    # print('---------------------------------------------')

    # renaming API book information to fit our standard format
    # print(f'fuck it book: {book}')
    # if "id" in book:
    #     # print(f'IN ID IN CLEANBOOKDATA')
    #     volume_id = book["id"]
    #     cleaned_book[id_key] = f"{book_id_identifier}{volume_id}"

    # if its an ebook fuck off

    if "saleInfo" in book:
        if book["saleInfo"]["isEbook"]:
            return standardmedia.getStandardEmptyMedia()

    # checks for valid key exists
    # if not isValidID(cleaned_book[id_key][1:]):
    #     # print(f"book id: {cleaned_book[id_key]}")
    #     return standardmedia.getStandardEmptyMedia()

    volume_info = book["volumeInfo"]

    if "industryIdentifiers" not in volume_info:
        return standardmedia.getStandardEmptyMedia()

    if (
        volume_info["industryIdentifiers"][0]["type"] == "OTHER"
        or volume_info["industryIdentifiers"][0]["type"] == "ISSN"
    ):
        return standardmedia.getStandardEmptyMedia()

    # if 'title' in volume_info:
    #     cleaned_book[title_key] = volume_info['title']

    # if 'description' in volume_info:
    #     cleaned_book[description_key] = volume_info['description']
    # print('CLEANING DP BEFORE AVERAGE RATING')
    if "averageRating" in volume_info:
        cleaned_book[overall_rating_key] = volume_info["averageRating"]
        cleaned_book[overall_rating_key] = roundOverallRating(
            cleaned_book[overall_rating_key]
        )

    # # collecting isbns from book
    # if 'industryIdentifiers' in volume_info:
    #     if len (volume_info['industryIdentifiers']) > 1:
    #         isbn = volume_info['industryIdentifiers'][1]['identifier'] # isbn 13
    #     else :
    #         isbn = volume_info['industryIdentifiers'][0]['identifier'] # isbn 10

    #     # open library cover image url
    #     url = f"https://covers.openlibrary.org/b/isbn/{isbn}-L.jpg"

    #     image_request = requests.head(url, allow_redirects=True, timeout=5)

    #     if image_request.status_code != 200:
    #         cleaned_book[image_key] = media_invalid_str_key
    #     else:
    #         cleaned_book[image_key] = f"https://covers.openlibrary.org/b/isbn/{isbn}-L.jpg"
    #         cleaned_book[id_key] = f"{book_id_identifier}{isbn}"

    # if 'imageLinks' in volume_info:
    #     if 'extraLarge' in volume_info['imageLinks']:
    #         cleaned_book[image_key] = getBookImageURL(volume_info['imageLinks']['extraLarge'])
    #     elif 'large' in volume_info['imageLinks']:
    #         cleaned_book[image_key] = getBookImageURL(volume_info['imageLinks']['large'])
    #     elif 'medium' in volume_info['imageLinks']:
    #         cleaned_book[image_key] = getBookImageURL(volume_info['imageLinks']['medium'])
    #     elif 'thumbnail' in volume_info['imageLinks']:
    #         cleaned_book[image_key] = getBookImageURL(volume_info['imageLinks']['thumbnail'])
    # print('CLEANING DP BEFORE RATING COUNT')
    if "ratingsCount" in volume_info:
        cleaned_book[api_review_count_key] = volume_info["ratingsCount"]

    # if 'categories' in volume_info:
    #     cleaned_book[genres_key] = cleanGenres(volume_info['categories'])

    # if 'publishedDate' in volume_info:
    #     date_split = volume_info['publishedDate'].split('-')
    #     cleaned_book[release_date_key] = date_split[0]  # only take the year part

    # if 'authors' in volume_info:
    #     cleaned_book[creator_key] = ', '.join(volume_info['authors'])  # join authors with comma
    # print('SUCCESSFULLY CLEANED BOOK DATA')
    return cleaned_book


ISBNdb_edition_ignored = set(
    [
        "2nd",
        "3rd",
        "4th",
        "5th",
        "reprint",
        "anniversary",
        "special edition",
        "illustrated",
        "revised",
        "updated",
        "collector",
        "abridged",
        "audiobook",
    ]
)


def bookAddRatingFromGP(book: dict, gp_book: dict):
    """
    adds rating and review count information from the given gp_book to the given book, if it is not already present in the book and is present in the gp_book
    """
    if (
        book[overall_rating_key] == media_invalid_int_key
        and "averageRating" in gp_book["volumeInfo"]
    ):
        book[overall_rating_key] = gp_book["volumeInfo"]["averageRating"]
        book[overall_rating_key] = roundOverallRating(book[overall_rating_key])

    if (
        book[api_review_count_key] == media_invalid_int_key
        and "ratingsCount" in gp_book["volumeInfo"]
    ):
        book[api_review_count_key] = gp_book["volumeInfo"]["ratingsCount"]

    return book


def bookAddRatingFromSupabase(book: dict, sp_info):
    """
    adds rating and review count information from the given sp_info to the given book, if it is not already present in the book and is present in the sp_info
    """
    if (
        book[overall_rating_key] == media_invalid_int_key
        and "average_rating" in sp_info
    ):
        book[overall_rating_key] = sp_info["average_rating"]
        book[overall_rating_key] = roundOverallRating(book[overall_rating_key])

    if (
        book[api_review_count_key] == media_invalid_int_key
        and "review_count" in sp_info
    ):
        book[api_review_count_key] = sp_info["review_count"]

    return book


ISBNdb_binding_ignored = set(["audio", "ebook", "kindle"])


def cleanBookDataISBNdb(book: dict, lang: str = "en"):
    """
    Assumes the given dictionary is a book, and cleans it to fit the standard described at the top of the file.
    if the given book has an invalid id then it will return an empty media dictionary with default values. (id value will be 'N/A')

    cleans library of congress book
    """
    if book['title'].lower() == 'dune':
        print('='*60)
        print(f'pre cleaning book:')
        print(f'{book}')
        print('='*60)
    cleaned_book = standardmedia.getStandardEmptyMedia()
    # print(f'BOOK BEFORE CLEANING: {book}')

    # ignore media that is not in the given language.
    if "language" not in book or book["language"] != lang:
        return cleaned_book

    if "edition" in book:
        normalized_edition = book["edition"].lower()
        # if invalid edition is included
        for ignored_edition in ISBNdb_edition_ignored:
            if ignored_edition in normalized_edition:
                return cleaned_book
        # if normalized_edition.contains
        # return cleaned_book

    if "binding" in book:
        normalized_binding = book["binding"].lower()
        for ignored_binding in ISBNdb_binding_ignored:
            if ignored_binding in normalized_binding:
                return cleaned_book

    if "title" in book:
        cleaned_book[title_key] = book["title"]

    if "overview" in book:
        cleaned_book[description_key] = removeMarkdown(book["overview"])

    if "synopsis" in book:
        cleaned_book[description_key] = removeMarkdown(book["synopsis"])

    if "image" in book:
        image_url = book.get("image")

        if not (
            image_url == "https://covers.isbndb.com/covers/0000000000000.jpg"
            or image_url == "https://covers.isbndb.com/covers/default.jpg"
        ):
            cleaned_book[image_key] = book["image"]

    if "isbn" in book:
        isbn = book["isbn"]
        # isbn = identifiers # TODO: make sure this is always valid. # ALSO do we need to clean this more?

        cleaned_book[id_key] = f"{book_id_identifier}{isbn}"

    if "subjects" in book:
        cleaned_book[genres_key] = cleanGenres(book["subjects"])

    if "date_published" in book:
        date_split = str(book["date_published"]).split("-")
        cleaned_book[release_date_key] = date_split[0]  # only take the year part

    if "authors" in book:
        cleaned_book[creator_key] = " | ".join(
            book["authors"]
        )  # join authors with comma

    if "pages" in book:
        cleaned_book[media_length_key] = book.get("pages", 0)

    # print(f'cleaned_book[media_length_key]: {cleaned_book[media_length_key]}')

    if cleaned_book[media_length_key] == 0:
        print(";ILESUVJKNVSJKNLVJKNVSDJKNVSDJKNVDSNJKDSVNJKDSVJKNDVSKNJDSV")

    return cleaned_book


def cleanMovieData(movie: dict, credits: dict, runtime_info: dict):
    """
    Assumes the given dictionary is a movie, and cleans it to fit the standard described at the top of the file.
    if the given movie has an invalid id then it will return an empty media dictionary with default values. (id value will be 'N/A')

    movie is the movie information from TMDB
    credits is the credits information for the movie from TMDB
    """
    cleaned_movie = standardmedia.getStandardEmptyMedia()

    # print(f'MOVIE BEFORE CLEANING: {movie}')

    # renaming API movie information to fit our standard format
    if "mid" in movie:
        cleaned_movie[id_key] = f"m{movie['mid']}"
    elif "id" in movie:
        cleaned_movie[id_key] = f"m{movie['id']}"

    # checks if valid key exists.
    if not isValidID(cleaned_movie[id_key][1:]):
        # print(f"movie id: {cleaned_movie[id_key]}")
        return standardmedia.getStandardEmptyMedia()

    if "title" in movie:
        cleaned_movie[title_key] = movie["title"]

    if "overview" in movie:
        cleaned_movie[description_key] = movie["overview"]

    # rename 'vote_average' to 'overall_rating' and make scoring out of 5 (instead of 10)
    if "vote_average" in movie:
        cleaned_movie[overall_rating_key] = (movie["vote_average"]) / 2
        cleaned_movie[overall_rating_key] = roundOverallRating(
            cleaned_movie[overall_rating_key]
        )

    if "poster_path" in movie:
        cleaned_movie[image_key] = f"{tmdb_poster_base_url}{movie['poster_path']}"
        if cleaned_movie[image_key] == f"{tmdb_poster_base_url}None":
            cleaned_movie[image_key] = media_invalid_str_key

    if "vote_count" in movie:
        cleaned_movie[api_review_count_key] = movie["vote_count"]

    if "genre_ids" in movie:
        cleaned_movie[genres_key] = cleanGenres(
            [
                TMDB_movie_genre_map.get(genre_id, "N/A")
                for genre_id in movie["genre_ids"]
            ]
        )
    elif "genres" in movie:
        cleaned_movie[genres_key] = cleanGenres(
            [
                (
                    genre["name"]
                    if "name" in genre
                    else TMDB_movie_genre_map.get(genre["id"], "N/A")
                )
                for genre in movie["genres"]
            ]
        )

    if "release_date" in movie:
        date_split = movie["release_date"].split("-")
        cleaned_movie[release_date_key] = date_split[0]  # only take the year part

    # getting director from credits
    for person in credits["crew"]:
        if person.get("job") == "Director":
            cleaned_movie[creator_key] = person.get("name")
            break

    cleaned_movie[media_length_key] = runtime_info.get("total_runtime", 0)

    return cleaned_movie


def cleanTvData(tv: dict, credits: dict, runtime_info: dict):
    """
    Assumes the given dictionary is a tv show, and cleans it to fit the standard described at the top of the file.
    if the given tv show has an invalid id then it will return an empty media dictionary with default values. (id value will be 'N/A')

    tv is the tv show information from TMDB
    credits is the credits information  for the tv showfrom TMDB
    """
    cleaned_tv = standardmedia.getStandardEmptyMedia()

    # renaming API tv information to fit our standard format
    if "tid" in tv:
        cleaned_tv[id_key] = f"t{tv['tid']}"
    else:
        cleaned_tv[id_key] = f"t{tv['id']}"

    # checks if valid key exists
    if not isValidID(cleaned_tv[id_key][1:]):
        # print(f"tv id: {cleaned_tv[id_key]}")
        return standardmedia.getStandardEmptyMedia()

    if "name" in tv:
        cleaned_tv[title_key] = tv["name"]

    if "overview" in tv:
        cleaned_tv[description_key] = tv["overview"]

    if "vote_average" in tv:
        cleaned_tv[overall_rating_key] = tv["vote_average"] / 2
        cleaned_tv[overall_rating_key] = roundOverallRating(
            cleaned_tv[overall_rating_key]
        )

    if "poster_path" in tv:
        cleaned_tv[image_key] = f"{tmdb_poster_base_url}{tv['poster_path']}"
        if cleaned_tv[image_key] == f"{tmdb_poster_base_url}None":
            cleaned_tv[image_key] = media_invalid_str_key

    if "vote_count" in tv:
        cleaned_tv[api_review_count_key] = tv["vote_count"]

    if "genre_ids" in tv:
        cleaned_tv[genres_key] = cleanGenres(
            [TMDB_tv_genre_map.get(genre_id, "N/A") for genre_id in tv["genre_ids"]]
        )
    elif "genres" in tv:
        cleaned_tv[genres_key] = cleanGenres(
            [
                (
                    genre["name"]
                    if "name" in genre
                    else TMDB_tv_genre_map.get(genre["id"], "N/A")
                )
                for genre in tv["genres"]
            ]
        )

    if "first_air_date" in tv:
        date_split = tv["first_air_date"].split("-")
        cleaned_tv[release_date_key] = date_split[0]  # only take the year part

    cleaned_tv[creator_key] = ""

    for crew_member in credits["crew"]:
        if (
            crew_member.get("job") == "Creator"
            or crew_member.get("job") == "Created By"
        ):
            cleaned_tv[creator_key] = (
                cleaned_tv[creator_key] + ", " + crew_member.get("name")
            )

    # remove leading comma and space
    if len(cleaned_tv[creator_key]) > 0:
        cleaned_tv[creator_key] = cleaned_tv[creator_key][2:]
    # if no creators found
    else:
        cleaned_tv[creator_key] = media_invalid_str_key

    # print(f'cleaned tv: {cleaned_tv}')

    cleaned_tv[season_count_key] = tv.get("number_of_seasons", 0)

    cleaned_tv[media_length_key] = runtime_info.get("total_runtime", 0)

    # print(f'cleaned_tv[media_length_key]: {cleaned_tv[media_length_key]}')
    return cleaned_tv


def cleanTMDBReview(review: dict) -> dict:
    """
    Cleans the given review from TMDB to fit our standard format.

    if the given review has an invalid id then it will return an empty review dictionary with default values. (id value will be 'N/A')
    """
    # print(f'cleanTMDBReview review: {review}')
    author_details = review["author_details"]
    cleaned_review = standardmedia.getStandardEmptyReview()
    spoiler = False

    if "username" in author_details:
        cleaned_review["username"] = author_details["username"]
        cleaned_review["uid"] = author_details["username"]
    else:
        return standardmedia.getStandardEmptyReview()

    if "rating" in author_details and author_details["rating"]:
        cleaned_review["rating"] = roundOverallRating(author_details["rating"] / 2)

    if "content" in review:
        cleaned_review["review_text"] = review["content"]
        spoiler = checkContainsSpoilers(review["content"])

    if "created_at" in review:
        cleaned_review["finished_on"] = review["created_at"].split("T")[0]

    cleaned_review["spoiler"] = spoiler

    return cleaned_review


def cleanSupabaseReview(review: dict) -> dict:
    """
    Cleans the given review from Supabase to fit our standard format.

    if the given review has an invalid id then it will return an empty review dictionary with default values. (id value will be 'N/A')
    """
    cleaned_review = review.copy()

    if review_spoiler_key in review and review[review_spoiler_key]:
        cleaned_review[review_spoiler_key] = review[review_spoiler_key]
        return cleaned_review

    if review_text_key in review:
        cleaned_review[review_spoiler_key] = checkContainsSpoilers(
            review[review_text_key]
        )

    return cleaned_review

def cleanWhereToWatchTMDB(where_to_watch_data: dict) -> list:
    """
    Cleans the given where to watch data to fit our standard format.
    returns a dictionary with the following format:
    {
        'streaming': [
            {
                'service': '...',
                'logo': '...'
            },
            ...
        ],
        'buy': [
            {
                'service': '...',
                'logo': '...'
            },
            ...
        ]
    }

    if invalid data is given, an empty dictionary is returned.
    """

    where_to_watch_cleaned = {
        'flatrate': [],
        'buy': [],
    }
    service_types = []

    where_to_watch_data = where_to_watch_data.get('results', {})
    
    where_to_watch_data = where_to_watch_data.get('US', {})  # TODO: make this dynamic based on user location

    if not where_to_watch_data:
        return {}
    
    if 'flatrate' in where_to_watch_data: 
        service_types.append('flatrate')

    if 'buy' in where_to_watch_data:
        service_types.append('buy')
    
    for service_type in service_types:

        for service in where_to_watch_data[service_type]:
            where_to_watch_cleaned[service_type].append({
                'service': service['provider_name'],
                'logo': f'{tmdb_logo_base_url}{service["logo_path"]}'
            })
    
    return where_to_watch_cleaned


def filterMediaByType(media_list: list, media_type: str):
    """
    filters the given list of media by type and returns a list of only said type. If tpye is a then the entire list is returned.
    """
    if media_type == "a":
        return media_list
    
    filtered_list = []

    for media in media_list:
        if media[id_key][0] == media_type:
            filtered_list.append(media)

    return filtered_list


def filterReviewsByType(review_list: list, media_type: str):
    """
    filters the given list of reviews by type and returns a list of only said type. If tpye is a then the entire list is returned.
    """
    if media_type == "a":
        return review_list
    
    filtered_list = []

    for review in review_list:
        if review[review_media_id_key][0] == media_type:
            filtered_list.append(review)

    return filtered_list



def checkValidAuthor(author: str) -> bool:
    """
    Checks if the given author string is a valid author name.
    If the authors name is just Author or empty than it is considered invalid.
    """

    author = author.lower()
    return not (author == '' or author == 'author')
 
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

    # TODO: remove common words? (like movie edition, etc)


    word_list = text.split()
    word_list.sort()

    word_str = " ".join(word_list)
    
    return word_str

def checkSameBook(book_1: dict, book_2: dict) -> bool:
    title_1_words = stripTextForBooks(book_1[title_key])


    title_2_words = stripTextForBooks(book_2[title_key])

    author_1_words = stripTextForBooks(book_1[creator_key])
    author_2_words = stripTextForBooks(book_2[creator_key])

    title_same = title_1_words == title_2_words 
    author_same = author_1_words == author_2_words

    return title_same and author_same