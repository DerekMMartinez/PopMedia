"""
Controller module for handling media recommendations and search functionality.

Converts media into dictionary of form:


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

import json
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import supabase_report_logic
import book_collection_service
import tmdb_collection_service
import firebase_admin
from firebase_admin import auth, credentials as firebase_credentials
from fastapi.middleware.cors import CORSMiddleware
import os
from datetime import datetime
import asyncio

import standardmedia
import datacleaning
import mergelists
import external_media_service
import supabase_user_logic
import supabase_review_logic
import supabase_badge_logic
import profile_picture_logic
import supabase_playlist_logic


def initialize_firebase():
    if not firebase_admin._apps:
        cred = firebase_credentials.Certificate(
            json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"])
        )
        firebase_admin.initialize_app(cred)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    initialize_firebase()
    yield
    # Shutdown logic
    await httpx_controller_client.aclose()
    await httpx_rec_client.aclose()


app = FastAPI(lifespan=lifespan)


# allowing any clients to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------------------------------------------------------------
# Supabase information
# -----------------------------------------------------------------------------------
from supabase_connection_logic import supabase

# --------------------------------------------------------------------------------
# time check variables for testing runtime of different methods, set to True to print start and end times
# --------------------------------------------------------------------------------
TIME_CHECK = False
REC_TIME_CHECK = False
SUPABASE_USER_TIME_CHECK = True
SUPABASE_REVIEW_TIME_CHECK = False
MEDIA_API_TIME_CHECK = True
SUPABASE_BADGE_TIME_CHECK = False
PINECONE_LOGIC_TIME_CHECK = False
ANNUAL_RECAP_TIME_CHECK = False
SUPABASE_PLAYLIST_TIME_CHECK = True


def logTimeCheck(message: str, time_check_variable: bool):
    if time_check_variable:
        print(
            f"---------------- {message}: time({datetime.now()}), pid({os.getpid()}) -------------------"
        )


# ---------------------------------------------------------------------------------------------------
# Recommendations and Pinecone information
# ---------------------------------------------------------------------------------------------------
REC_PORT = "8001"
PINECONE_PORT = "8002"
ANNUAL_RECAP_PORT = "8003"
OUR_SERVER_API_URL = "http://localhost"


# -----------------------------------------------------------------------------------
# httpx information
# -----------------------------------------------------------------------------------
# import httpx_logic
from httpx_logic import (
    httpx_controller_client,
    httpx_rec_client,
    sendAsyncHttpRequestPost,
    sendAsyncHttpRequestGet,
)

import pinecone_logic

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


# ---------------------------------------------------------------------------------------------------
# Get User Recommendation Logic
# ---------------------------------------------------------------------------------------------------


@app.post("/getRecommendationsForUser")
async def getRecommendationsForUser(query: dict) -> list:
    """
    Gets recommendations for the user

    query is of form:
        - uid: str (user id to get recommendations for)
        - type: str (type of query,'a' for all, 'b' for book, 'm' for movie, 't' for tv)

    returns list of recommended media items for the user
    """
    # getting recommendations from recommendation model via API
    logTimeCheck("getRecommendationsForUser STARTING", REC_TIME_CHECK)

    # amount of recommendations to get
    query["amount"] = 10

    rec_media = await sendAsyncHttpRequestGet(
        httpx_controller_client,
        f"{OUR_SERVER_API_URL}:{REC_PORT}/getRecForUser",
        params={
            'uid': query['uid'],
            "media_type": query["type"],
            }
    )

    # rec_media = await sendAsyncHttpRequestPost(
    #     httpx_controller_client,
    #     f"{OUR_SERVER_API_URL}:{REC_PORT}/getRecForUser",
    #     json=query,
    # )

    logTimeCheck("getRecommendationsForUser FINISHED", REC_TIME_CHECK)
    return rec_media


@app.post("/getRecommendationsForMedia")
async def getRecommendationsForMedia(query: dict) -> list:
    """
    Get recommendations for specific media

    query is of form:
        - media_id: str (id of the media to get recommendations for)
        - type: str type of recommendations (type of media, b for book, m for movie, t for tv)

        returns a list of recommended media items similar to the given media item
    """
    try:
        logTimeCheck("getRecommendationsForMedia STARTING", REC_TIME_CHECK)

        query["amount"] = 10

        rec_media = await sendAsyncHttpRequestGet(
            httpx_controller_client,
            f"{OUR_SERVER_API_URL}:{REC_PORT}/getRecForMedia",
            params={
                'media_id': query['media_id'],
                "media_type": query["type"],
                }
        )
        
        # rec_media = await sendAsyncHttpRequestPost(
        #     httpx_controller_client,
        #     f"{OUR_SERVER_API_URL}:{REC_PORT}/getRecForMedia",
        #     json=query,
        # )

        logTimeCheck("getRecommendationsForMedia FINISHED", REC_TIME_CHECK)
        return rec_media

    except Exception:
        raise Exception


@app.post("/getRecommendationsForVibeSearch")
async def getRecommendationsForVibeSearch(query: dict) -> list:
    """
    get recommendations for vibe search

    query is of form:
        - text: str (the text to get recommendations for)
        - uid: str (the user id to get recommendations for, in case we want to personalize the vibe search results based on the user's preferences)
        - type: str (the type of media to get recommendations for, b for book, m for movie, t for tv)


    returns a list of recommended media items that fit the vibe of the given text
    """
    try:
        logTimeCheck("getRecForVibeSearch STARTING", REC_TIME_CHECK)

        query["amount"] = 10
        rec_media = await sendAsyncHttpRequestGet(
            httpx_controller_client,
            f"{OUR_SERVER_API_URL}:{REC_PORT}/getRecForVibeSearch",
            params={
                'text': query['text'],
                "media_type": query["type"],
                }
        )
      
      
      
        # rec_media = await sendAsyncHttpRequestPost(
        #     httpx_controller_client,
        #     f"{OUR_SERVER_API_URL}:{REC_PORT}/getRecForVibeSearch",
        #     json=query,
        # )

        logTimeCheck("getRecForVibeSearch FINISHED", REC_TIME_CHECK)
        return rec_media
    except Exception as e:
        print(
            f"-----------------------exception in getRecommendationsForVibeSearch: {e}----------------------"
        )
        raise Exception


# ---------------------------------------------------------------------------------------------------
# Supabase User Logic
# ---------------------------------------------------------------------------------------------------


@app.post("/postUserReview")
async def postUserReview(review: dict):
    """
    Adds a users review to the database in one of the three tables depending on what type of media it is
    that they are reviewing using the information provided in the review dictionary.


    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("postUserReview STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.postUserReview(review)

        logTimeCheck("postUserReview FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postUserReview --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/postNewUser")
async def postNewUser(user: dict):
    """
    Adds a new user to the supabase database using the information provided in the user dictionary

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("postNewUser STARTING", SUPABASE_USER_TIME_CHECK)

        result = await supabase_user_logic.postNewUser(user)

        logTimeCheck("postNewUser FINISHED", SUPABASE_USER_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postNewUser --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getCheckUser")
async def getCheckUser(uid: str):
    """
    Checks that a user with that id is in the supabase database

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("getCheckUser STARTING", SUPABASE_USER_TIME_CHECK)

        result = await asyncio.to_thread(supabase_user_logic.getCheckUser, uid)

        logTimeCheck("getCheckUser FINISHED", SUPABASE_USER_TIME_CHECK)
        return result

    except Exception as e:
        print(
            f"-------------------------------- CHECKPOINT FAILURE getCheckUser error: {e} --------------------------------"
        )
        return {"status": "error", "message": str(e)}


# ---------------------------------------------------------------------------------------------------
# API Endpoint Logic
# ---------------------------------------------------------------------------------------------------


@app.post("/getMediaUsingIdSearch")
async def getMediaUsingIdSearch(query: dict) -> list:
    """
    Gets a single media item from the Googe Play API that fit the given request criteria

    query are of form: (details listed below)
        - mode: str (type of request, 'id_search' to search for single media using an id)
        - type: str  (m for movies, t for tv)       (for 'id_search')
        - media_id: str                             (for 'id_search')
    """

    logTimeCheck("getMediaUsingIdSearch STARTING", MEDIA_API_TIME_CHECK)

    media = await external_media_service.getMediaFromExternalAPIs(
        request={"mode": "id_search", id_key: query[id_key], "type": query["type"]}
    )

    logTimeCheck("getMediaUsingIdSearch FINISHED", MEDIA_API_TIME_CHECK)
    return media

import pinecone_logic_pt
# Should allow the frontend to access this method using HTTP and query parameters (right now just a string parameter)
@app.post("/getMediaUsingSearch")
async def getMediaUsingSearch(query: dict) -> list:
    """
    Gets a list of books from the Googe Play API that fit the given request criteria

    query are of form: (details listed below)
        - mode: str (type of request, 'search' for searching via input, 'id_search' to search for single media using an id)
        - input: str                                (for 'search')
        - type: str  (b for books, m for movies, t for tv, a for all)       (for 'search' and 'id_search')
        - media_id: str                             (for 'id_search')
    """
    query_user_input = query["input"]

    # validate and clean the user input
    user_input = datacleaning.validateUserInput(query_user_input)

    # if the user's input is invalid, return empty list
    if user_input == "":
        return []

    query_type = query["type"]
    amount_to_return = 30  # amount to grab
    amount_to_get = 30  # amount to get from each API to ensure enough results after combining and filtering

    # get books movies and tv show lists from APIs
    books = []
    movies = []
    tv = []

    logTimeCheck("getMediaUsingSearch STARTING", MEDIA_API_TIME_CHECK)
    tasks_by_type = {}

    if query_type in ["a", "b"]:
        tasks_by_type["b"] = external_media_service.getMediaFromExternalAPIs(
            {
                "mode": "search",
                "title": user_input,
                "amount": amount_to_get,
                "type": "b",
            }
        )

    if query_type in ["a", "m"]:
        tasks_by_type["m"] = external_media_service.getMediaFromExternalAPIs(
            {
                "mode": "search",
                "title": user_input,
                "amount": amount_to_get,
                "type": "m",
            }
        )

    if query_type in ["a", "t"]:
        tasks_by_type["t"] = external_media_service.getMediaFromExternalAPIs(
            {
                "mode": "search",
                "title": user_input,
                "amount": amount_to_get,
                "type": "t",
            }
        )

    keys = list(tasks_by_type.keys())
    values = await asyncio.gather(*(tasks_by_type[k] for k in keys))
    result_map = dict(zip(keys, values))

    books = result_map.get("b", [])
    movies = result_map.get("m", [])
    tv = result_map.get("t", [])

    logTimeCheck("getMediaUsingSearch AFTER", MEDIA_API_TIME_CHECK)
    # combine all media into one list
    logTimeCheck("getMediaUsingSearch BEFORE MERGE", MEDIA_API_TIME_CHECK)
    combined_media_list = mergelists.mergeThreeLists(books, movies, tv)

    logTimeCheck("getMediaUsingSearch AFTER MERGE", MEDIA_API_TIME_CHECK)

    # TODO: should we change what criteria the list should be sorted in?
    final_results = combined_media_list[:amount_to_return]

    # for media in final_results:
    #     asyncio.create_task(pinecone_logic_pt.getMediaUsingID(media))
    #     media_id = media.get(id_key)
    #     # collects where to watch information for ea m/t media
    #     if media_id and media_id.startswith((movie_id_identifier, tv_id_identifier)):
    #         media["where_to_watch"] = await external_media_service.getWhereToWatchFromTMDB(
    #             media_id
    #         )


    logTimeCheck("getMediaUsingSearch FINISHED", MEDIA_API_TIME_CHECK)
    return final_results


async def fetch_media_for_review(review):
    media_type = review[id_key][0]
    if media_type == "b":
        media_response = (
            supabase.table("books").select("*").eq(id_key, review[id_key]).execute()
        )
        return (media_type, review, media_response.data)
    else:
        media = await external_media_service.getMediaFromExternalAPIs(
            request={"mode": "id_search", id_key: review[id_key], "type": media_type}
        )
        return (media_type, review, media)


# -----------------------------------------------------------------------------------
# Firebase information
# -----------------------------------------------------------------------------------
security = HTTPBearer()


@app.get("/getUser")
async def getUser(
    uid: str, credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        logTimeCheck("getUser STARTING", SUPABASE_USER_TIME_CHECK)

        uid = validateUserViaCredentials(uid, auth_credentials=credentials)

        result = await asyncio.to_thread(supabase_user_logic.getUser, uid)

        logTimeCheck("getUser FINISHED", SUPABASE_USER_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getUser --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/updateUserReview")
async def updateUserReview(
    review: dict,
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    """
    Updates a user's review in the database using the information provided in the review dictionary.


    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("updateUserReview STARTING", SUPABASE_REVIEW_TIME_CHECK)
        requester_id = validateUserViaCredentials("me", auth_credentials=credentials)
        if requester_id == review["uid"] or supabase_user_logic.getAdmin(requester_id):
            result = await supabase_review_logic.updateUserReview(review)

            return result
        else:
            return {"status": "error", "message": "Unauthorized"}
        logTimeCheck("updateUserReview FINISHED", SUPABASE_REVIEW_TIME_CHECK)
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updateUserReview --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getUsername")
async def getUsername(uid: str):
    """
    Gets the username of a user based off of the uid

    Returns a dictionary with the username
    """
    try:
        logTimeCheck("getUsername STARTING", SUPABASE_USER_TIME_CHECK)

        result = await supabase_user_logic.getUsername(uid)

        logTimeCheck("getUsername FINISHED", SUPABASE_USER_TIME_CHECK)

        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/getTrending")
async def getTrending(query: dict) -> dict:
    """
    Retrieves all of the given user reviews and their corresponding media

    query is in form:
        - uid: str (id of the user)
        - type: str (type of query, b for books, m for movies, t for tv)

    returns a dictionary of form:
        - 'b': [] list of tuples each tuple is of form: (user's book review, corresponding media)
        - 'm': [] list of tuples each tuple is of form: (user's movie review, corresponding media)
        - 't': [] list of tuples each tuple is of form: (user's tv review, corresponding media)
    """
    try:
        logTimeCheck("getTrending STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.getTrending(query)

        logTimeCheck("getTrending FINISHED", SUPABASE_REVIEW_TIME_CHECK)

        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getTrending --------------------------------"
        )
        return {"status": "error", "message": str(e)}


# TODO: this is wrong, we aren't checking if user_id is actually the person decoded from the token.
def validateUserViaCredentials(
    user_id, auth_credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = getattr(auth_credentials, "credentials", None)
    if not isinstance(token, str) or not token.strip():
        raise HTTPException(status_code=401, detail="Missing or invalid bearer token")

    decoded = auth.verify_id_token(token)

    # Do checks here to see if decoded[uid] has permission to get this user/whatever else
    if user_id == "me":
        user_id = decoded["uid"]

    return user_id


@app.post("/createNewFollow")
async def createNewFollow(
    user_id: str,
    following_id: str,
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    try:
        logTimeCheck("createNewFollow STARTING", SUPABASE_USER_TIME_CHECK)
        user_id = validateUserViaCredentials(user_id, auth_credentials=credentials)

        await supabase_user_logic.createNewFollow(user_id, following_id)

        logTimeCheck("createNewFollow FINISHED", SUPABASE_USER_TIME_CHECK)

        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/getAdmin")
async def getAdmin(user_id: str):
    try:
        is_admin = supabase_user_logic.getAdmin(user_id)
        return {"is_admin": is_admin}
    except Exception as e:
        print("DEBUG: getAdmin error", e)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/deleteFollow")
async def deleteFollow(
    user_id: str,
    following_id: str,
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    try:
        logTimeCheck("deleteFollow STARTING", SUPABASE_USER_TIME_CHECK)
        requester_id = validateUserViaCredentials(user_id, auth_credentials=credentials)
        if requester_id == user_id or supabase_user_logic.getAdmin(requester_id):
            await supabase_user_logic.deleteFollow(user_id, following_id)

        logTimeCheck("deleteFollow FINISHED", SUPABASE_USER_TIME_CHECK)

        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/checkFollow")
async def checkFollow(
    user_id: str,
    following_id: str,
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    try:
        logTimeCheck("checkFollow STARTING", SUPABASE_USER_TIME_CHECK)

        user_id = validateUserViaCredentials(user_id, auth_credentials=credentials)

        result = await asyncio.to_thread(
            supabase_user_logic.checkFollow, user_id, following_id
        )

        logTimeCheck("checkFollow FINISHED", SUPABASE_USER_TIME_CHECK)

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# returns all users that THIS user follows
@app.get("/fetchFollowing")
async def fetchFollowing(
    user_id: str, credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        logTimeCheck("fetchFollowing STARTING", SUPABASE_USER_TIME_CHECK)

        user_id = validateUserViaCredentials(user_id, auth_credentials=credentials)

        result = await supabase_user_logic.fetchFollowing(user_id)

        logTimeCheck("fetchFollowing FINISHED", SUPABASE_USER_TIME_CHECK)

        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# returns all users that follow THIS user
@app.get("/fetchFollowers")
async def fetchFollowers(
    following_id: str, credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        logTimeCheck("fetchFollowers STARTING", SUPABASE_USER_TIME_CHECK)

        following_id = validateUserViaCredentials(
            following_id, auth_credentials=credentials
        )

        result = await supabase_user_logic.fetchFollowers(following_id)

        logTimeCheck("fetchFollowers FINISHED", SUPABASE_USER_TIME_CHECK)

        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# TODO: would it be better if i returned a dict of 4 lists? or is this better?
@app.post("/getDiscoverSearch")
async def getDiscoverSearch(query: dict) -> list:
    """
    Searches through media and usernames that fit the given query

    query is of form:
        - input: str (the user's search input)
        - type: str (type of search, a for all, b for books, m for movies, t for tv)


    return a list of all search items in a list
    """
    query_user_input = query["input"]
    query_type = query["type"]
    user_input = datacleaning.validateUserInput(query_user_input)
    # if the user's input is invalid, return empty list
    if user_input == "":
        return []
    # print(f'getDiscoverSearch USER INPUT: {user_input}')
    logTimeCheck("getDiscoverSearch STARTING", SUPABASE_USER_TIME_CHECK)
    media_search_results = []
    user_search_results = []
    playlist_search_results = []
    tasks = {}

    if query_type in ["a", book_id_identifier, movie_id_identifier, tv_id_identifier]:
        tasks["media"] = asyncio.create_task(
            getMediaUsingSearch(
                {"mode": "search", "input": user_input, "type": query_type}
            )
        )
        # media_search_results = await getMediaUsingSearch({'mode': 'search', 'input': user_input, 'type': query_type}),

    if query_type in ["a", "u"]:
        tasks["user"] = asyncio.create_task(
            supabase_user_logic.getUsersUsingSearch({"input": user_input})
        )
        # user_search_results = await asyncio.to_thread(supabase_user_logic.getUsersUsingSearch, {'input': user_input})

    if query_type in ["a", "p"]:
        tasks["playlist"] = asyncio.create_task(
            supabase_playlist_logic.getPlaylistsUsingSearch({"input": user_input})
        )

    keys = list(tasks.keys())
    values = await asyncio.gather(*(tasks[k] for k in keys))
    result_map = dict(zip(keys, values))

    # TODO: unnessaecaryly weird
    # results = await asyncio.gather(*tasks)
    media_search_results = result_map.get("media", [])
    user_search_results = result_map.get("user", [])
    playlist_search_results = result_map.get("playlist", [])

    final_result = mergelists.mergeThreeLists(
        media_search_results, user_search_results, playlist_search_results
    )

    logTimeCheck("getDiscoverSearch FINISHED", SUPABASE_USER_TIME_CHECK)
    return final_result


@app.post("/postNewBadgeEarned")
async def postNewBadgeEarned(badgeEarned: dict):
    """
    Adds a new badge_earned to the supabase database using the information provided in the badgeEarned dictionary

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("postNewBadgeEarned STARTING", SUPABASE_BADGE_TIME_CHECK)

        result = await asyncio.to_thread(
            supabase_badge_logic.postNewBadgeEarned, badgeEarned
        )

        logTimeCheck("postNewBadgeEarned FINISHED", SUPABASE_BADGE_TIME_CHECK)

        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postNewBadgeEarned --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getBadge")
async def getBadge(bid: str):
    try:
        logTimeCheck("getBadge STARTING", SUPABASE_BADGE_TIME_CHECK)
        result = await asyncio.to_thread(supabase_badge_logic.getBadgeFromId, bid)
        logTimeCheck("getBadge FINISHED", SUPABASE_BADGE_TIME_CHECK)

        return result
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgeCount --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getBadgesEarned")
async def getBadgesEarned(uid: str):
    """
    Gets all badges earned by a specific person from the database


    Returns a list of tuples with badge earned at 0 and the badge at 1.
    """
    try:
        logTimeCheck("getBadgesEarned STARTING", SUPABASE_BADGE_TIME_CHECK)
        result = await asyncio.to_thread(supabase_badge_logic.getBadgesEarned, uid)
        logTimeCheck("getBadgesEarned FINISHED", SUPABASE_BADGE_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgesEarned --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getBadgeCount")
async def getBadgeCount(uid: str):
    try:
        logTimeCheck("getBadgeCount STARTING", SUPABASE_BADGE_TIME_CHECK)

        result = await asyncio.to_thread(supabase_badge_logic.getBadgeCount, uid)

        logTimeCheck("getBadgeCount FINISHED", SUPABASE_BADGE_TIME_CHECK)

        return result
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgeCount --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getReviewCount")
async def getReviewCount(uid: str):
    try:
        logTimeCheck("getReviewCount STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await asyncio.to_thread(supabase_review_logic.getReviewCount, uid)

        logTimeCheck("getReviewCount FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getReviewCount --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getMediaReviews")
async def getMediaReviews(media_id: str) -> list:
    """
    Gets all reviews for a specific piece of media from the database


    Returns a dictionary with lists of reviews
    """
    try:
        logTimeCheck("getMediaReviews STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.getMediaReviews(media_id)

        logTimeCheck("getMediaReviews FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getMediaReviews --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/checkUsernameTaken")
async def checkUsernameTaken(username: str, email: str):
    """
    Checks that a user with that USERNAME is in the supabase database

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("checkUsernameTaken STARTING", SUPABASE_USER_TIME_CHECK)

        result = await asyncio.to_thread(
            supabase_user_logic.checkUsernameTaken, username, email
        )

        logTimeCheck("checkUsernameTaken FINISHED", SUPABASE_USER_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE checkUsernameTaken --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getFriends")
async def getFriends(
    user_id: str, credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        logTimeCheck("getFriends STARTING", SUPABASE_USER_TIME_CHECK)

        user_id = validateUserViaCredentials(user_id, auth_credentials=credentials)

        result = await supabase_user_logic.getFriends(user_id)

        logTimeCheck("getFriends FINISHED", SUPABASE_USER_TIME_CHECK)

        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/getFollowingMediaReviews")
async def getFollowingMediaReviews(
    uid: str,
    type: str = "a",
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> list:
    """ """
    uid = validateUserViaCredentials(uid, auth_credentials=credentials)

    try:
        logTimeCheck("getFollowingMediaReviews STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.getFollowingMediaReviews(uid, type)

        logTimeCheck("getFollowingMediaReviews FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def getUserReviews(uid: str, type: str = "a") -> list:
    """
    Gets all reviews from the user database for a specific user based on the uid


    Returns a list of tuples of form: (review, media)
    """
    try:
        logTimeCheck("getUserReviews STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.getUserReviews(uid, type)

        logTimeCheck("getUserReviews FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getUserReviews --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getUserMediaReviews")
async def getUserMediaReviews(
    request_uid: str, target_uid: str, type: str = "a"
) -> list:
    """
    Retrieves all of the given user reviews and their corresponding media


    requester_id: str (id of the user making the request)
    target_user_id: str (id of the user whose reviews are being requested)
    type: str (type of query, b for books, m for movies, t for tv)
    visibility: str (me, friend, public)


    returns a list of tuples opf form: (review, media)
    """
    pass
    try:
        logTimeCheck("getUserMediaReviews STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.getUserMediaReview(
            request_uid, target_uid, type
        )

        logTimeCheck("getUserMediaReviews FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getUserMediaReviews --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/checkFriendship")
async def checkFriendship(uid1: str, uid2: str) -> bool:
    """
    Checks if two users are friends (if they follow each other)

    Returns true if they are friends, false if not
    """
    try:
        logTimeCheck("getCheckFriendship STARTING", SUPABASE_USER_TIME_CHECK)

        result = await asyncio.to_thread(
            supabase_review_logic.checkFriendship, uid1, uid2
        )

        logTimeCheck("getCheckFriendship FINISHED", SUPABASE_USER_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getCheckFriendship --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/checkBadgeEarned")
async def checkBadgeEarned(uid: str, bid: str) -> bool:
    """
    Checks if a user has earned a specific badge

    Returns true if they have earned it, false if not
    """
    try:
        logTimeCheck("checkBadgeEarned STARTING", SUPABASE_BADGE_TIME_CHECK)

        result = await supabase_badge_logic.checkBadgeEarned(uid, bid)
        # print(f'checkBadgeEarned result: {result}')
        logTimeCheck("checkBadgeEarned FINISHED", SUPABASE_BADGE_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE checkBadgeEarned --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getReviewsFromMediaAPI")
async def getReviewsFromMediaAPI(media_id: str) -> list:
    """
    Gets all reviews for a specific piece of media from the database


    Returns a dictionary with lists of reviews
    """
    try:
        logTimeCheck("getReviewsFromMediaAPI STARTING", MEDIA_API_TIME_CHECK)

        result = await external_media_service.getReviewsFromMediaAPI(media_id)

        logTimeCheck("getReviewsFromMediaAPI FINISHED", MEDIA_API_TIME_CHECK)

        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getReviewsFromMediaAPI --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/getPreSignedUrl")
async def sign_upload(
    req: profile_picture_logic.SignRequest,
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    """
    Returns either a presigned PUT URL (simple) or a presigned POST (enforces size via policy).
    Client should use the returned uploadUrl/fields accordingly.
    """
    user_id = validateUserViaCredentials("me", auth_credentials=credentials)
    try:
        return profile_picture_logic.sign_upload(user_id, req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/confirmUpload")
async def confirm_upload_endpoint(
    payload: dict, credentials: HTTPAuthorizationCredentials = Depends(security)
):
    user_id = validateUserViaCredentials("me", auth_credentials=credentials)
    try:
        ok, object_key = profile_picture_logic.confirm_upload(user_id, payload)
        if ok:
            return {"status": "ok", "objectKey": object_key}
        else:
            # confirm_upload should not normally return False
            raise HTTPException(
                status_code=500, detail="Unknown error during confirmation"
            )
    except HTTPException:
        # re-raise known HTTPExceptions so FastAPI uses the right status code
        raise
    except Exception:
        # log and return 500
        print("confirmUpload failed for user %s", user_id)
        raise HTTPException(status_code=500, detail="Could not confirm upload")


@app.get("/deleteUserReview")
async def deleteUserReview(uid: str, media_id: str):
    try:
        logTimeCheck("deleteUserReview STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.deleteUserReview(uid, media_id)

        logTimeCheck("deleteUserReview FINISHED", SUPABASE_REVIEW_TIME_CHECK)

        return result
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error deleting user review: {str(e)}"
        )


@app.get("/getBookRatingInfo")
async def getBookRatingInfo(book_id: str) -> tuple:
    """
    Gets the average rating and total ratings for a book based on the book id

    Returns a dictionary of form:
        - average_rating: float
    """

    try:
        logTimeCheck("getBookRatingInfo STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await book_collection_service.getRatingInfo(book_id)

        logTimeCheck("getBookRatingInfo FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBookRatingInfo --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/deleteUserPhoto")
async def deleteUserPhoto(uid: str) -> dict:
    try:
        # logTimeCheck
        result = await supabase_user_logic.deleteUserPhoto(uid)

        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/deleteAccount")
async def deleteAccount(uid: str) -> dict:
    try:
        return supabase_user_logic.deleteAccount(uid)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/getCreditsForMedia")
async def getCreditsForMedia(media_id: str) -> dict:
    try:
        result = await tmdb_collection_service.getCredits(media_id=media_id)

        return result
    except:
        return {"status": "error", "message": "getCreditsForMedia failed"}


@app.get("/getTvSeasonCount")
async def getTvSeasonCount(media_id: str) -> int:
    try:
        result = await tmdb_collection_service.getTvSeasonCount(media_id=media_id)
        return result
    except:
        print(f"getTvSeasonCount failed for media_id: {media_id}")
        return -1


@app.get("/getAnnualRecapDataForUser")
async def getAnnualRecapDataForUser(uid: str, year: str = "2026") -> dict:
    try:
        logTimeCheck("getAnnualRecapDataForUser STARTING", ANNUAL_RECAP_TIME_CHECK)

        result = await sendAsyncHttpRequestGet(
            client=httpx_controller_client,
            url=f"{OUR_SERVER_API_URL}:{ANNUAL_RECAP_PORT}/getRecapDataForUser",
            params={"uid": uid, "year": year},
        )

        logTimeCheck("getAnnualRecapDataForUser FINISHED", ANNUAL_RECAP_TIME_CHECK)
        return result
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getAnnualRecapDataForUser --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getSeasonReviews")
async def getSeasonReviews(review_id: int) -> list:
    try:
        logTimeCheck("getSeasonReviews STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.getSeasonReviews(review_id)

        logTimeCheck("getSeasonReviews FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getSeasonReviews --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/updateSeasonReview")
async def updateSeaasonReview(review: dict) -> dict:
    try:
        logTimeCheck("updateSeasonReview STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.updateSeasonReview(review=review)

        logTimeCheck("updateSeasonReview FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updateSeasonReview --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/deleteSeasonReview")
async def deleteSeasonReview(rid: int, season_number: int) -> dict:
    try:
        logTimeCheck("deleteSeasonReview STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.deleteSeasonReview(
            rid=rid, season_number=season_number
        )

        logTimeCheck("deleteSeasonReview FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE deleteSeasonReview --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getSeasonReviewsForUser")
async def getSeasonReviewsForUser(uid: str, tv_id: int) -> list:
    """
    Gets all season reviews for a specific user and media from the database


    Returns a list of season reviews
    """
    try:
        logTimeCheck("getAllUserSeasonReviews STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_review_logic.getSeasonReviewsForUser(uid, tv_id)

        logTimeCheck("getAllUserSeasonReviews FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getAllUserSeasonReviews --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getPlaylists")
async def getPlaylists(uid: str) -> list:
    """
    Gets all the playlists connected to a specific userbased on uid


    Returns a list of playlists as dictionaries
    """

    try:
        logTimeCheck("getPlaylists STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.getPlaylists(uid)

        logTimeCheck("getPlaylists FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getPlaylists --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/deletePlaylist")
async def deletePlaylist(pid: int):
    """
    Deletes a playlist from the playlist attributes table and associated rows in other playlist tables
    """

    try:
        logTimeCheck("deletePlaylist STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.deletePlaylist(pid)

        logTimeCheck("deletePlaylist FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE deletePlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getCollaborators")
async def getCollaborators(pid: int, includeOwner: bool, ownerId: str) -> list:
    """
    Gets all the collaborator connected to a specific playlist based on pid and the owner id includeOwner is true


    Returns a list of collaborators (users) as dictionaries
    """

    try:
        logTimeCheck("getCollaborators STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.getCollaborators(
            pid, includeOwner, ownerId
        )

        logTimeCheck("getCollaborators FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getCollaborators --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getPlaylistMedia")
async def getPlaylistMedia(pid: int, media_type: str) -> list:
    """
    Gets all the media of the specified type connected to a specific playlist based on pid


    Returns a list of media as dictionaries
    """

    try:
        logTimeCheck("getPlaylistMedia STARTING", SUPABASE_PLAYLIST_TIME_CHECK)
        result = await supabase_playlist_logic.getPlaylistMedia(pid, media_type)


        logTimeCheck("getPlaylistMedia FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getPlaylistMedia --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/addMediaToPlaylist")
async def addMediaToPlaylist(pid: int, media_id: str):
    """
    Puts a media_id and pid row in the playlist media table
    """
    try:
        logTimeCheck("addMediaToPlaylist STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.addMediaToPlaylist(pid, media_id)

        logTimeCheck("addMediaToPlaylist FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE addMediaToPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/addCollaboratorToPlaylist")
async def addCollaboratorToPlaylist(pid: int, uid: str):
    """
    Puts a uid and pid row in the playlist collaborator table
    """
    try:
        logTimeCheck("addCollaboratorToPlaylist STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.addCollaboratorToPlaylist(pid, uid)

        logTimeCheck("addCollaboratorToPlaylist FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE addCollaboratorToPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/deleteMediaFromPlaylist")
async def deleteMediaFromPlaylist(pid: int, media_id: str):
    """
    Deletes a media_id and pid row in the playlist media table
    """

    try:
        logTimeCheck("deleteMediaFromPlaylist STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.deleteMediaFromPlaylist(pid, media_id)

        logTimeCheck("deleteMediaFromPlaylist FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE deleteMediaFromPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/deleteCollaboratorFromPlaylist")
async def deleteCollaboratorFromPlaylist(pid: int, uid: str):
    """
    Deletes a uid and pid row in the playlist collaborator table
    """

    try:
        logTimeCheck(
            "deleteCollaboratorFromPlaylist STARTING", SUPABASE_PLAYLIST_TIME_CHECK
        )

        result = await supabase_playlist_logic.deleteCollaboratorFromPlaylist(pid, uid)

        logTimeCheck(
            "deleteCollaboratorFromPlaylist FINISHED", SUPABASE_PLAYLIST_TIME_CHECK
        )
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE deleteCollaboratorFromPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/postReport")
async def postReport(
    associated_id: str,
    type: str,
    reason: str,
    reporter: str,
    created_at: str,
    resolved: bool,
) -> dict:
    """
    Posts a report to the database with the given information

    associated_id: str (id of the media/review/user being reported)
    type: str (type of report, e.g. 'review', 'user', 'media')
    reason: str (reason for the report)
    reporter: str (uid of the user making the report)
    created_at: str (timestamp of when the report was made)
    resolved: bool (whether or not the report has been resolved)

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("postReport STARTING", SUPABASE_USER_TIME_CHECK)

        result = supabase_report_logic.postReport(
            associated_id, type, reason, reporter, created_at, resolved
        )

        logTimeCheck("postReport FINISHED", SUPABASE_USER_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postReport --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/resolveReport")
async def resolveReport(issue_id: int, resolved: bool):
    try:
        logTimeCheck("resolveReport STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = supabase_report_logic.resolveReport(issue_id, resolved)

        logTimeCheck("resolveReport FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE resolveReport --------------------------------"
        )
        print("DEBUG: error:", str(e))
        return {"status": "error", "message": str(e)}


@app.get("/getReviewFromReport")
async def getReviewFromReport(associated_id: str) -> list:
    """
    Gets the review associated with a specific report based on the associated id and type


    Returns a review as a dictionary
    """
    try:
        logTimeCheck("getReviewFromReport STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = await supabase_report_logic.getReviewMediaFromReport(associated_id)

        logTimeCheck("getReviewFromReport FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getReviewFromReport --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getReport")
async def getReport(resolved: bool) -> list:
    try:
        logTimeCheck("getReport STARTING", SUPABASE_REVIEW_TIME_CHECK)

        result = supabase_report_logic.getReport(resolved)

        logTimeCheck("geReprot FINISHED", SUPABASE_REVIEW_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getReport --------------------------------"
        )
        print("DEBUG: error:", str(e))
        return {"status": "error", "message": str(e)}


@app.post("/postPlaylist")
async def postPlaylist(
    uid: str, name: str, description: str, image_url: str, public: bool
) -> int:
    """
    Posts a playlist to the playlist attributes table in the database and returns the pid


    Returns the pid as an int
    """

    try:
        logTimeCheck("postPlaylist STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.postPlaylist(
            uid, name, description, image_url, public
        )

        logTimeCheck("postPlaylist FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/updatePlaylist")
async def updatePlaylist(
    pid: int, uid: str, name: str, description: str, image_url: str, public: bool
) -> int:
    """
    Updates a playlist in the playlist attributes table in the database and returns the pid


    Returns the pid as an int
    """

    try:
        logTimeCheck("updatePlaylist STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await supabase_playlist_logic.updatePlaylist(
            pid, uid, name, description, image_url, public
        )

        logTimeCheck("updatePlaylist FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updatePlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getSeasonInfo")
async def getSeasonInfo(media_id: str, season_number: int) -> dict:
    """
    Gets the season info for a specific tv show from the database


    Returns a dictionary with season info
    """
    try:
        logTimeCheck("getSeasonInfo STARTING", MEDIA_API_TIME_CHECK)

        result = await tmdb_collection_service.getSeasonInfo(
            media_id, season_number
        )

        logTimeCheck("getSeasonInfo FINISHED", MEDIA_API_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getSeasonInfo --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getCreditsForMediaSeason")
async def getCreditsForMediaSeason(media_id: str, season_number: int) -> dict:
    """
    Gets the credits for a specific season of a tv show from the database


    Returns a dictionary with credits info
    """
    try:
        logTimeCheck("getCreditsForMediaSeason STARTING", MEDIA_API_TIME_CHECK)

        result = await tmdb_collection_service.getCreditsForMediaSeason(
            media_id, season_number
        )

        logTimeCheck("getCreditsForMediaSeason FINISHED", MEDIA_API_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getCreditsForMediaSeason --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.post("/postMediaBadgeEarned")
async def postMediaBadgeEarned(media_id: str, uid: str, name: str, image_url: str):
    """
    Adds a new media badge earned to the supabase database using the information provided in the badgeEarned dictionary

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        logTimeCheck("postMediaBadgeEarned STARTING", SUPABASE_BADGE_TIME_CHECK)

        result = await supabase_badge_logic.postMediaBadgeEarned(
            uid, media_id, name, image_url
        )

        logTimeCheck("postMediaBadgeEarned FINISHED", SUPABASE_BADGE_TIME_CHECK)

        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postMediaBadgeEarned --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/checkMediaBadgeEarned")
async def checkMediaBadgeEarned(uid: str, media_id: str):
    try:
        logTimeCheck("checkMediaBadgeEarned STARTING", SUPABASE_BADGE_TIME_CHECK)

        result = await supabase_badge_logic.checkMediaBadgeEarned(uid, media_id)

        logTimeCheck("checkMediaBadgeEarned FINISHED", SUPABASE_BADGE_TIME_CHECK)

        return {"status": "success", "earned": result}
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE checkMediaBadgeEarned --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getBadgeWithMediaId")
async def getBadgeWithMediaId(media_id: str):
    try:
        logTimeCheck("getBadgeWithMediaId STARTING", SUPABASE_BADGE_TIME_CHECK)

        result = await supabase_badge_logic.getBadgeWithMediaId(media_id)

        logTimeCheck("getBadgeWithMediaId FINISHED", SUPABASE_BADGE_TIME_CHECK)

        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgeWithMediaId --------------------------------"
        )
        return {"status": "error", "message": str(e)}


@app.get("/getBadgesEarnedInYear")
async def getBadgesEarnedInYear(uid: str, year: str) -> list:
    """
    Gets all badges earned by a specific person in a specific year from the database
a

    Returns a list of tuples with badge earned at 0 and the badge at 1.
    """
    try:
        logTimeCheck("getBadgesEarnedInYear STARTING", SUPABASE_BADGE_TIME_CHECK)
        result = await supabase_badge_logic.getBadgesEarnedInYear(uid, year)
        logTimeCheck("getBadgesEarnedInYear FINISHED", SUPABASE_BADGE_TIME_CHECK)
        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgesEarnedInYear --------------------------------"
        )
        return {"status": "error", "message": str(e)}

@app.get("/getPlaylistRec")
async def getPlaylistRec(pid: int, media_type: str) -> list:
    """
    Gets a media recommendation for a specific playlist based on the media in the playlist and the media type

    """
    try:
        logTimeCheck("getPlaylistRec STARTING", SUPABASE_PLAYLIST_TIME_CHECK)

        result = await sendAsyncHttpRequestGet(
            client=httpx_controller_client,
            url=f"{OUR_SERVER_API_URL}:{REC_PORT}/getRecForPlayList",
            params={"pid": pid, "media_type": media_type},)
        
        logTimeCheck("getPlaylistRec FINISHED", SUPABASE_PLAYLIST_TIME_CHECK)
        return result

    except Exception as e:
        print(
            f"-------------------------------- CHECKPOINT FAILURE getPlaylistRec, error: {e} --------------------------------"
        )
        return {"status": "error", "message": str(e)}
    
@app.get("/getWhereToWatch")
async def getWhereToWatch(media_id: str) -> dict:
    """
    Gets where to watch information for a specific piece of media based on the media id

    Returns a dictionary with where to watch information
    """
    try:
        logTimeCheck("getWhereToWatch STARTING", MEDIA_API_TIME_CHECK)

        result = await tmdb_collection_service.getWhereToWatch(media_id)

        logTimeCheck("getWhereToWatch FINISHED", MEDIA_API_TIME_CHECK)
        return result

    except Exception as e:
        print(
            f"-------------------------------- CHECKPOINT FAILURE getWhereToWatch, error: {e} --------------------------------"
        )
        return {"status": "error", "message": str(e)}