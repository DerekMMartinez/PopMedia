import datacleaning
import os
from fastapi import HTTPException

from datetime import datetime

import supabase_user_logic
import standardmedia
import external_media_service
import cache_lock_logic

# ---------------------------------------------------------------------------------
# Standard Media Keys and Identifiers
# ---------------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------------
# Supabase information
# ---------------------------------------------------------------------------------
from supabase_connection_logic import supabase

# -----------------------------------------------------------------------------------
# cache information
# -----------------------------------------------------------------------------------
from cachetools import TTLCache, LRUCache
from threading import RLock
from collections import defaultdict
import asyncio


def hourCalculator(minues: float) -> int:
    return int(minues * 60 * 60)


def minuteCalculator(minutes: float) -> int:
    return int(minutes * 60)


LRU_lock = RLock()  # Lock for synchronizing access to the LRU cache
LRU_cache = LRUCache(
    maxsize=1024
)  # Cache for ID search results (doesn't expire, just keeps the most recent 1024 searches)

TTL_lock = RLock()  # Lock for synchronizing access to the TTL cache
TTL_cache = TTLCache(maxsize=1024, ttl=minuteCalculator(15))  # Cache for 3 hours

TRENDING_TTL_CACHE = TTLCache(
    maxsize=1024, ttl=hourCalculator(24)
)  # Cache for trending media for 1 hour
TRENDING_LOCK = defaultdict(
    asyncio.Lock
)  # Lock for synchronizing access to the trending media cache, using a defaultdict to create a new lock for each unique key


USER_REVIEW_LRU_CACHE = LRUCache(
    maxsize=1024
)  # Cache for user reviews, doesn't expire, just keeps the most recent 1024 searches
USER_REVIEW_LRU_LOCK = defaultdict(
    asyncio.Lock
)  # Lock for synchronizing access to the user review cache, using a defaultdict to create a new lock for each unique key


SUPABASE_GET_BOOK_CACHE = TTLCache(
    maxsize=1024, ttl=hourCalculator(3)
)  # Cache for getting book information from supabase, expires after 3 hours since book data can update more frequently
SUPABASE_GET_BOOK_LOCK = defaultdict(
    asyncio.Lock
)  # Lock for synchronizing access to the get book from supabase cache, using a defaultdict to create a new lock for each unique key


USER_REVIEW_TIME_CHECK = False


def logTimeCheck(message: str, time_check_variable: bool):
    if time_check_variable:
        print(
            f"---------------- {message}: time({datetime.now()}), pid({os.getpid()}) -------------------"
        )


async def sortReviewMediaListByDate(review_media_list: list) -> list:
    """
    Takes in a list of (review, media) tuples.

    returns list sorted by date (most recent first)
    """
    sorted_reviews = sorted(
        review_media_list,
        key=lambda x: datetime.strptime(x[0][review_finished_on_key], "%Y-%m-%d"),
        reverse=True,
    )

    return sorted_reviews


async def getBookRatingInfo(book_id: str) -> dict:
    """
    Gets a book's rating information from the database using the isbn


    Returns a dictionary with the book's overall rating and review count

    """
    try:
        response = (
            supabase.table("book_rating").select("*").eq(id_key, book_id).execute()
        )

        if response.data and len(response.data) > 0:
            return response.data[0]
        else:
            return {
                "status": "error",
                "message": "No rating information found for this book",
            }

    except Exception as e:
        print(
            f"-------------------------------- CHECKPOINT FAILURE (supabase_review_logic) getBookRatingInfo, book_id: {book_id} --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def postBookRatingInfo(book_id: str, overall_rating: float, review_count: int):
    """
    Adds a book's rating information to the database using the information provided in the parameters


    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """

    try:
        response = (
            supabase.table("book_rating")
            .insert(
                {
                    id_key: book_id,
                    overall_rating_key: overall_rating,
                    api_review_count_key: review_count,
                }
            )
            .execute()
        )
        return {"status": "success", "table": "book_rating"}

    except Exception as e:
        print(
            f"-------------------------------- CHECKPOINT FAILURE postBookRatingInfo, book_id: {book_id}, overall_rating: {overall_rating}, review_count: {review_count} --------------------------------"
        )
        return {"status": "error", "message": str(e)}


def getReviewCount(uid: str):
    book_response = (
        supabase.table("book_reviews")
        .select("*", count="exact")
        .eq("uid", uid)
        .execute()
    )

    movie_response = (
        supabase.table("movie_reviews")
        .select("*", count="exact")
        .eq("uid", uid)
        .execute()
    )

    tv_response = (
        supabase.table("television_reviews")
        .select("*", count="exact")
        .eq("uid", uid)
        .execute()
    )
    #    print(f"---------------- book review count: {book_response.count}, movie review count: {movie_response.count}, tv review count: {tv_response.count} -----------------")
    sum = (
        (tv_response.count or 0)
        + (movie_response.count or 0)
        + (book_response.count or 0)
    )
    #    print(f"---------------- total review count for uid {uid}: {sum} -----------------"  )
    return sum


async def postUserReviewCached(
    uid: str,
    media_id: str,
    rating: float,
    review_text: str,
    review_visibility: str,
    finished_on: str,
    spoiler: bool,
):
    """
    Adds a users review to the database in one of the three tables depending on what type of media it is
    that they are reviewing using the information provided in the parameters.


    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    type = media_id[0]
    # args_type = (uid, type)
    # args_all = (uid, 'a')

    try:
        if media_id.startswith("m"):
            table = "movie_reviews"
        elif media_id.startswith("t"):
            table = "television_reviews"
        else:
            table = "book_reviews"

        response = (
            supabase.table(table)
            .insert(
                {
                    "uid": uid,
                    "media_id": media_id,
                    "rating": rating,
                    "review_visibility": review_visibility,
                    "review_text": review_text,
                    "finished_on": finished_on,
                    "spoiler": spoiler,
                }
            )
            .execute()
        )

        return {"status": "success", "table": table}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postNewUser --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def postUserReview(review: dict):
    """
    Adds a users review to the database in one of the three tables depending on what type of media it is
    that they are reviewing using the information provided in the review dictionary.


    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    media_id = review[id_key]

    try:
        result = await postUserReviewCached(
            uid=review["uid"],
            media_id=media_id,
            rating=review["rating"],
            review_text=review["review_text"],
            review_visibility=review["review_visibility"],
            finished_on=review["finished_on"],
            spoiler=review["spoiler"],
        )   
        args = (review["uid"],)
        key = (review["uid"],)    

        await cache_lock_logic.repolulateCache(
            args=args,
            key=key,
            CACHE=USER_REVIEW_LRU_CACHE,
            LOCK=USER_REVIEW_LRU_LOCK,
            function=getAllUserReviewsCached,
        )

        return result

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updateUserReview --------------------------------"
        )
        return {"status": "error", "message": f"{str(e)}"}


async def cleanSupabaseReview(review: dict) -> dict:
    """
    Helper function that takes in a review and attaches the username and if it contains a spoiler to it based on the uid

    Returns the review with the username attached as a new key value pair:
    {
        ...review,
        "username": str (the username of the user, used for displaying on frontend)
        "spoiler": bool (whether the review contains spoilers)
    }
    """
    review = datacleaning.cleanSupabaseReview(review)

    result = await supabase_user_logic.getUsername(review["uid"])

    username = result["username"]

    return {
        **review,
        "username": f"{username}",
    }


async def cleanSupabaseReviews(reviews: list) -> list:
    """
    Helper function that takes in a list of reviews and attaches the username to it based on the uid

    Returns the reviews with the username attached as a new key value pair:
    [
        {
            ...review,
            "username": str (the username of the user, used for displaying on frontend)
        },
        ...
    ]
    """
    tasks = [cleanSupabaseReview(review) for review in reviews]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Filter out exceptions and only return successful results
    valid_results = []
    for result in results:
        if isinstance(result, Exception):
            print(f"Error attaching username to review: {result}")
            continue
        valid_results.append(result)

    return valid_results


async def matchReviewToMedia(review: dict) -> tuple:
    """
    Helper function that takes in a review and matches it to the corresponding media based on the media_id and type of media

    Returns a tuple of the form (review, media) where review is the original review and media is the corresponding media item
    """
    # print(f'A;FIHAURDFLBHJ: review: {review}')
    media_id = review[id_key]
    media_type = media_id[0]

    # if media_type == 'b':
    #     media = await getBookFromSupabase(media_id)
    # else:
    media = await external_media_service.getMediaFromExternalAPIs(
        request={"mode": "id_search", id_key: media_id, "type": media_type}
    )

    return (review, media[0])


async def getAllUserReviewsCached(uid: str) -> dict:
    """
    Gets all reviews from the user database for a specific user based on the uid and type of media

    returns a dictionary of form:
    {
        'result': list of the user reviews sorted by date (most recent first)
    }

    NOTICE: THIS FUNCTION SHOULD BE CACHED, PLEASE CALL WITH getAllUserReviewsCached TO ENSURE PROPER CACHE AND LOCKING
    """
    try:
        print(
            "================== Getting All User Reviews from Supabase NOT CACHED ===================="
        )
        books = []
        movies = []
        television = []
        # username = supabase_user_logic.getUsername(uid)['username']



        
        bookResponse = (
            supabase.table("book_reviews")
            .select("*")
            .eq("uid", uid)
            .order(
                "finished_on", desc=True
            )  # order by finished on descending so that the most recent reviews are first
            .execute()
        )

        books = await cleanSupabaseReviews(bookResponse.data)


        movieResponse = (
            supabase.table("movie_reviews")
            .select("*")
            .eq("uid", uid)
            .order(
                "finished_on", desc=True
            )  # order by finished on descending so that the most recent reviews are first
            .execute()
        )
        movies = await cleanSupabaseReviews(movieResponse.data)

      
        televisionResponse = (
            supabase.table("television_reviews")
            .select("*")
            .eq("uid", uid)
            .order(
                "finished_on", desc=True
            )  # order by finished on descending so that the most recent reviews are first
            .execute()
        )

        television = await cleanSupabaseReviews(televisionResponse.data)

        # for tv in television:
        #     print(
        #         f"---------------- television review genres: {tv.get(genres_key, [])} -----------------"
        #     )

        all_reviews = []
        all_reviews.extend(books)
        all_reviews.extend(movies)
        all_reviews.extend(television)

        return {"result": all_reviews}

    except Exception as e:
        return {
            "status": "error",
            "message": f"getAllUserReviewsCached Params: ({uid}) error: {str(e)}",
        }


async def getAllUserReviews(uid: str) -> list:
    """
    Gets all reviews from the user database for a specific user based on the uid


    Returns a list of reviews

    each media review in the lists is of form:
    {
    "uid": str,
    "media_id": str,
    "rating": int,
    "type": str,
    "review_text": str,
    "finished_on": str,
    "username": str (the username of the user, used for displaying on frontend)
    }
    """
    args = (uid,)
    key = (uid,)

    result_dict = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=USER_REVIEW_LRU_CACHE,
        LOCK=USER_REVIEW_LRU_LOCK,
        function=getAllUserReviewsCached,
    )

    result = result_dict["result"]
    return result


async def getUserReviews(uid: str, media_type: str = "a", visibility: str = "me") -> list:
    all_reviews = await getAllUserReviews(uid)

    if "status" in all_reviews and all_reviews["status"] == "error":
        return all_reviews

    allowed = ["Public"]
    if visibility == "friend":
        allowed.append("Friends Only")
    elif visibility == "me":
        allowed.append("Friends Only")
        allowed.append("My Eyes Only")

    result = []


    # removing reviews that are not visible to the user based on the visibility parameter and attaching the media information to the review
    # as well as media that does not match the given media type
    for review in all_reviews:
        if review["review_visibility"] not in allowed:
            continue
        
        if media_type != "a" and review["media_id"][0] != media_type:
            continue

        result.append(review)

    return result


# TODO: come back and make this recash
async def updateUserReview(review: dict):
    media_id = review["media_id"]
    for key in review:
        print(f"{key}: {review[key]}")

    try:
        if media_id.startswith("m"):
            table = "movie_reviews"
            db_media_id = media_id

        elif media_id.startswith("t"):
            table = "television_reviews"
            db_media_id = media_id

        else:
            table = "book_reviews"
            db_media_id = media_id

        response = (
            supabase.table(table)
            .update(
                {
                    "rating": review["rating"],
                    "review_visibility": review["review_visibility"],
                    "review_text": review["review_text"],
                    "finished_on": review["finished_on"],
                    "spoiler": review["spoiler"],
                }
            )
            .eq("uid", review["uid"])
            .eq("media_id", db_media_id)
            .execute()
        )

        args = (review['uid'],)
        key = (review['uid'],)

        await cache_lock_logic.repolulateCache(
            args=args,
            key=key,
            CACHE=USER_REVIEW_LRU_CACHE,
            LOCK=USER_REVIEW_LRU_LOCK,
            function=getAllUserReviewsCached,
        )

    
        return {"status": "success", "table": table}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updateUserReview --------------------------------"
        )
        print(f"Error details: {e}")
        return {"status": "error", "message": str(e)}


async def getTrendingReviews(type: str):
    """
    Gets trending reviews

    Returns a dictionary with lists of books, movies, and television
    """
    try:
        books = []
        movies = []
        television = []
        if type == "a" or type == "b":
            books = supabase.rpc("get_trending_books_last_month").execute().data

        if type == "a" or type == "m":
            movies = supabase.rpc("get_trending_movies_last_month").execute().data

        if type == "a" or type == "t":
            television = supabase.rpc("get_trending_tv_shows_last_month").execute().data

        return {
            movie_id_identifier: movies,
            tv_id_identifier: television,
            book_id_identifier: books,
        }

    except Exception as e:
        print(
            "-------------------------------- getTrendingReviews CHECKPOINT FAILURE --------------------------------"
        )
        return {"status": "error", "message": str(e)}


# @cached(cache=TTL_cache, lock=TTL_lock)
async def getTrendingMediaCached(media_type: str) -> dict:
    trending_reviews = await getTrendingReviews(type)

    medias = {book_id_identifier: [], movie_id_identifier: [], tv_id_identifier: []}

    if "status" in trending_reviews:
        return medias

    # for each type of media
    for key in trending_reviews:
        reviews = trending_reviews[key]

        # for review in that type
        for review in reviews:
            media_type = review[id_key][0]
            review_media = await matchReviewToMedia(review)
            media = review_media[1]

            if not media:
                continue

            medias[media_type].append(media)

    return medias


# cached(cache=TTL_cache, lock=TTL_lock)
async def getTrending(query: dict) -> dict:
    """
    gets trending media based on the type of media specified in the query (book, movie, tv, or all)
    """
    media_type = query["type"]

    args = ('a',)
    key = ('a',)
    # return getTrendingMedia(media_type)
    result = await cache_lock_logic.cacheLockLogicTTL(
        args=args,
        key=key,
        CACHE=TRENDING_TTL_CACHE,
        LOCK=TRENDING_LOCK,
        function=getTrendingMediaCached,
    )

    # TODO: filter the result basedo nmedia type, and return a list not the psychopathic dictionary method.
    return result


async def getMediaReviews(media_id: str) -> list:
    """
    Gets all reviews for a specific piece of media from the database


    Returns a dictionary with lists of reviews
    """
    try:
        table = ""

        if media_id.startswith("m"):
            table = "movie_reviews"
        elif media_id.startswith("t"):
            table = "television_reviews"
        else:
            table = "book_reviews"

        our_response = supabase.table(table).select("*").eq(id_key, media_id).execute()
        our_reviews = our_response.data

        cleaned_reviews = await cleanSupabaseReviews(our_reviews)
        return cleaned_reviews

    except Exception as e:
        return {"status": "error", "message": str(e)}


def checkFriendship(uid1: str, uid2: str) -> bool:
    """
    Checks if two users are friends based on the database


    Returns true if they are friends and false if they are not
    """

    res1 = (
        supabase.table("following")
        .select("following_id")
        .eq("user_id", uid1)
        .eq("following_id", uid2)
        .execute()
    )

    res2 = (
        supabase.table("following")
        .select("following_id")
        .eq("user_id", uid2)
        .eq("following_id", uid1)
        .execute()
    )

    if not res1.data or not res2.data:
        return False

    result = (res1.data and len(res1.data) > 0) and (res2.data and len(res2.data) > 0)

    return len(res1.data) > 0 and len(res2.data) > 0


async def matchUserToMediaReviews(uid: str, media_id: str, type: str) -> dict:
    """
    Gets a specific users review for a specific piece of media from the database


    Returns a dictionary with the review if it exists
    """
    try:
        table = ""

        if media_id.startswith("m"):
            table = "movie_reviews"
        elif media_id.startswith("t"):
            table = "television_reviews"
        else:
            table = "book_reviews"

        response = (
            supabase.table(table)
            .select("*")
            .eq(id_key, media_id)
            .eq("uid", uid)
            .execute()
        )

        result = await cleanSupabaseReviews(response.data)
        return result[0] if result else None

    except Exception as e:
        return {"status": "error", "message": str(e)}


async def getUserMediaReview(
    request_uid: str, target_uid: str, type: str = "a"
) -> list:
    """
    Gets a specific users reviews from the database with appropriate visibility filtering


    Returns a dictionary with the reviews sorted by date (most recent first)
    """
    # print(f'--------------- getUserMediaReview BEFORE: {datetime.now()} ------------------')
    if request_uid == target_uid:
        visibility = "me"
    elif checkFriendship(request_uid, target_uid):
        visibility = "friend"
    else:
        visibility = "public"

    review_result = await getUserReviews(target_uid, type, visibility)
   

    # tasks = [matchReviewToMedia(review) for key in review_result.keys() for review in review_result[key]]
    tasks = [matchReviewToMedia(review) for review in review_result]

    matches = await asyncio.gather(*tasks, return_exceptions=True)

    result = []
    for match in matches:
        if isinstance(match, Exception):
            print(f"Error matching review to media: {match}")
            continue
        # result[match[0]['media_id'][0]].append(match)
        result.append(match)

    sorted_result = await sortReviewMediaListByDate(result)
    # print(f'--------------- getUserMediaReview AFTER: {datetime.now()} ------------------')
    return sorted_result




async def getFollowingMediaReviews(request_uid: str, type: str = "a") -> list:
    """
    Gets a specific users review for a specific piece of media from the database


    Returns a dictionary with the review if it exists
    """
    following_list = await supabase_user_logic.fetchFollowing(request_uid)

    # print(f"---------------- getFollowingMediaReviews BEFORE: {datetime.now()} -----------------")
    tasks = [
        getUserMediaReview(request_uid, following["uid"], type)
        for following in following_list
    ]
    friends_reviews = await asyncio.gather(*tasks, return_exceptions=True)

    all_reviews_list = []

    for friend_review_list in friends_reviews:
        # print(f'{'='*100}')
        # print(f'single_friend_review_list: {all_reviews_list}')
        all_reviews_list.extend(friend_review_list)

    # print(f"---------------- getFollowingMediaReviews AFTER: {datetime.now()} -----------------")
    sorted_friends_reviews = await sortReviewMediaListByDate(all_reviews_list)

    # print(f'sorted_friends_reviews: {sorted_friends_reviews}')
    return sorted_friends_reviews


async def deleteUserReview(uid: str, media_id: str):
    try:
        if media_id[0] == "m":
            table = "movie_reviews"
        if media_id[0] == "b":
            table = "book_reviews"
        if media_id[0] == "t":
            table = "television_reviews"

        result = (
            supabase.table(table)
            .delete()
            .eq("uid", uid)
            .eq("media_id", media_id)
            .execute()
        )
        args = (uid,)
        key = (uid,)
        await cache_lock_logic.repolulateCache(
            args=args,
            key=key,
            CACHE=USER_REVIEW_LRU_CACHE,
            LOCK=USER_REVIEW_LRU_LOCK,
            function=getAllUserReviewsCached,
        )

        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error deleting user review: {str(e)}"
        )


async def getSeasonReviews(review_id: str) -> list:
    """
    Gets all season reviews for a specific user review from the database.

    Returns a list of season review dictionaries.
    """
    try:
        table = "seasons"

        response = (
            supabase.table(table)
            .select("*")
            .eq("review_id", review_id)
            .order("season_number", desc=False)
            .execute()
        )

        return response.data if response.data else []

    except Exception as e:
        return {"status": "error", "message": str(e)}


async def updateSeasonReview(review: dict):
    try:
        table = "seasons"

        (
            supabase.table(table)
            .upsert(
                {
                    "review_id": review["review_id"],
                    "season_number": review["season_number"],
                    "rating": review["rating"],
                    "review_text": review["review_text"],
                    "finished_on": review["finished_on"],
                    "spoiler": review["spoiler"],
                    "watched": review["watched"],
                },
                on_conflict=["review_id, season_number"],
            )
            .execute()
        )
        return {"status": "success", "table": table}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updateSeasonReview --------------------------------"
        )
        print(f"Error details: {e}")
        return {"status": "error", "message": str(e)}


async def deleteSeasonReview(rid: int, season_number: int):
    try:
        table = "seasons"

        result = (
            supabase.table(table)
            .delete()
            .eq("review_id", rid)
            .eq("season_number", season_number)
            .execute()
        )

        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error deleting season review: {str(e)}"
        )


async def getSeasonReviewsForUser(uid: str, tv_id: int) -> list:
    try:
        response = (
            supabase.table("seasons")
            .select("*")
            # .eq("uid", uid)
            .eq("review_id", tv_id)
            .order("finished_on", desc=True)
            .execute()
        )

        seasons = response.data if response.data else []
        # cleaned_seasons = await cleanSupabaseReviews(seasons)
        return seasons

    except Exception as e:
        print("===========================================")
        print(f"Error getting all user season reviews for uid {uid}, error: {e}")
        print("===========================================")
        return {"status": "error", "message": str(e)}
