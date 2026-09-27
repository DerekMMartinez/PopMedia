import datetime
import standardmedia
import datacleaning
import os
from dotenv import load_dotenv


from datetime import datetime
import supabase_review_logic

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


import book_collection_service
import tmdb_collection_service

async def getMediaFromExternalAPIs(request: dict):
    """
    Gets a list of books from the Googe Play API that fit the given request criteria


    request are of form: (details listed below)
        - mode: str (type of request, 'search' for searching via input, 'id_search' to search for single media using an id)
        - title: str                                            (for 'search')
        - amount: int                                           (for 'search')
        - type: str  (b for books, m for movies, t for tv)      (for 'search' and 'id_search')
        - media_id: str                                         (for 'id_search')
    """
    if "type" not in request:
        return -1

    request["lang"] = "en"
    request_type = request["type"]

    # ----------------------------------------------------------------
    # if  requesting book data
    # ----------------------------------------------------------------
    if request_type == book_id_identifier:
        if request['mode'] == 'id_search':
            print('here?')
            book = await book_collection_service.getBookUsingID(book_id=request[id_key],  lang=request["lang"])
            return [book]
            
        if request['mode'] == 'search':
            book_searched = await book_collection_service.getBookUsingSearch(title=request['title'], request_amount=request['amount'],  lang=request["lang"])
            return book_searched

        # return await getBooksFromGooglePlay(request)

    # ----------------------------------------------------------------
    # if  requesting movie or tv data
    # ----------------------------------------------------------------
    elif request_type == movie_id_identifier or request_type == tv_id_identifier:
        if request['mode'] == 'id_search':
            media = await tmdb_collection_service.getMediaUsingID(media_id=request[id_key], request_type=request_type)
            return [media]
        
        if request['mode'] == 'search':
            media_searched = await tmdb_collection_service.getMediaUsingSearch(title=request['title'], request_amount=request['amount'], request_type=request_type)
            return media_searched
        
        # return await getMediaFromTMDB(request)

    return -5


async def getReviewsFromMediaAPI(media_id: str) -> list:
    """
    Gets api reviews for the given media id
    """

    media_type = media_id[0]
    result = []
    if media_type == movie_id_identifier or media_type == tv_id_identifier:
        result = await tmdb_collection_service.getReviewsFromMediaAPI(media_id=media_id)
        

    # for books, we currently only have ratings and review counts from google play, not actual reviews, so we will return an empty list for now. In the future, we can add functionality to get actual reviews for books as well.
    elif media_type == book_id_identifier:
        pass

    return result
