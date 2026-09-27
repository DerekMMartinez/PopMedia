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

# load .env file
load_dotenv()
# -----------------------------------------------------------------------------------
# TMDB API information
# -----------------------------------------------------------------------------------
TMDB_api_key = os.getenv("TMDB_API_KEY")
TMDB_base_api_url = "https://api.themoviedb.org/3"
TMDB_search_movie = "search/movie"
TMDB_search_tv = "search/tv"
TMDB_id_search_movie = "movie"
TMDB_id_search_tv = "tv"
max_number_of_pages = 10



# -----------------------------------------------------------------------------------
# cache information
# -----------------------------------------------------------------------------------
from cachetools import TTLCache, LRUCache
from collections import defaultdict
import asyncio
import cache_lock_logic


def hourCalculator(minues: float) -> int:
    return int(minues * 60 * 60)


def minuteCalculator(minutes: float) -> int:
    return int(minutes * 60)



# -----------------------------------------------------------------------------------
# timecheck information
# -----------------------------------------------------------------------------------

MEDIA_API_TIME_CHECK = False  # time check variable for testing runtime of media API methods, set to True to print start and end times


def logTimeCheck(message: str, time_check_variable: bool):
    if time_check_variable:
        print(
            f"---------------- {message}: time({datetime.now()}), pid({os.getpid()}) -------------------"
        )


# -----------------------------------------------------------------------------------
# httpx information
# -----------------------------------------------------------------------------------
from httpx_logic import httpx_controller_client, sendAsyncHttpRequestGet

# -----------------------------------------------------------------------------------
# media retrieval logic from external APIs (TMDB)
# -----------------------------------------------------------------------------------



# ====================================================================================
# review retrieval functions
# ====================================================================================

async def getReviewsCached(media_id: str, amount: int) -> list:
    """
    Gets the reviews information for the given media from TMDB API

    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, PLEASE CALL WITH cache_lock_logic.cacheLockLogicTTL TO ENSURE PROPER EFFICIENCY AND FUNCTIONALITY
    """
    print("but huh")
    media_type = media_id[0]
    media_id_search = ""

    if media_type == movie_id_identifier:
        media_id_search = TMDB_id_search_movie

    elif media_type == tv_id_identifier:
        media_id_search = TMDB_id_search_tv
    else:
        return {}

    media_id = media_id[1:]

    reviews = []
    result = []
    page = 1
    # collecting reviews until we have enough or there are no more reviews to collect or we have reached the max number of pages to check
    while len(reviews) < amount:
        data = await sendAsyncHttpRequestGet(
            httpx_controller_client,
            f"{TMDB_base_api_url}/{media_id_search}/{media_id}/reviews",
            params={"api_key": TMDB_api_key, "page": page},
        )
        if ("results" not in data) or (not data["results"]):
            break

        reviews.extend(data["results"])

        if (
            page >= data["total_pages"]
            or len(reviews) >= amount
            or page >= max_number_of_pages
        ):
            break

        page += 1

    result = [datacleaning.cleanTMDBReview(review) for review in reviews]
    return result[:amount]


REVIEW_CACHE = cache_lock_logic.CACHE_TTL(maxsize=10000, ttl=hourCalculator(6))
REVIEW_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getReviewsFromMediaAPI(media_id: str) -> list:
    """
    Gets api reviews for the given media id
    """

    media_type = media_id[0]
    result = []
    if media_type == movie_id_identifier or media_type == tv_id_identifier:
        args = (media_id, 5)
        key = (media_id, 5)
        result = await cache_lock_logic.cacheLockLogicTTL(
            args=args,
            key=key,
            CACHE=REVIEW_CACHE,
            LOCK=REVIEW_LOCK,
            function=getReviewsCached
        )

    # for books, we currently only have ratings and review counts from google play, not actual reviews, so we will return an empty list for now. In the future, we can add functionality to get actual reviews for books as well.
    elif media_type == book_id_identifier:
        pass

    return result

# ====================================================================================
# Where to watch information 
# ====================================================================================
async def getWhereToWatchCached(media_id: str) -> dict:
    """
    gets the where to watch information for the given media id from TMDB API. 

    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, PLEASE CALL WITH cache_lock_logic.cacheLockLogicTTL TO ENSURE PROPER EFFICIENCY AND FUNCTIONALITY
    """
    id_search_path = ''
    if media_id[0] == movie_id_identifier:
        id_search_path = TMDB_id_search_movie

    elif media_id[0] == tv_id_identifier:
        id_search_path = TMDB_id_search_tv

    else:
        return {"status": "error", "message": "Invalid media id for watch provider information"}

    where_to_watch_raw = await sendAsyncHttpRequestGet(
            httpx_controller_client,
            f"{TMDB_base_api_url}/{id_search_path}/{media_id[1:]}/watch/providers",
            params={"api_key": TMDB_api_key},
        )
    
    where_to_watch_cleaned = datacleaning.cleanWhereToWatchTMDB(where_to_watch_raw)
    
    if not where_to_watch_cleaned:
        return {'status': 'error', 'message':  'error no streaming information available'}

    return where_to_watch_cleaned


WHERE_TO_WATCH_CACHE = cache_lock_logic.CACHE_TTL(maxsize=10000, ttl=hourCalculator(24))
WHERE_TO_WATCH_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getWhereToWatch(media_id: str) -> dict:
    """
    gets the where to watch information for the given media id from TMDB API
    """
    args = (media_id,)
    key = (media_id,)
    where_to_watch = await cache_lock_logic.cacheLockLogicTTL(
        args=args,
        key=key,
        CACHE=WHERE_TO_WATCH_CACHE,
        LOCK=WHERE_TO_WATCH_LOCK,
        function=getWhereToWatchCached,
    )


    return where_to_watch


# ====================================================================================
# specific media information retrieval functions
# ====================================================================================

async def getCreditsForMediaSeason(media_id: str, season_number: int) -> dict:
    """
    Gets credits (cast, crew, etc) for a specific season of a TV show from TMDB API
    """
    if media_id[0] != tv_id_identifier:
        return {"status": "error", "message": "Invalid media id for TV season credits"}
    
    credits = await sendAsyncHttpRequestGet(
        httpx_controller_client,
        f"{TMDB_base_api_url}/{TMDB_id_search_tv}/{media_id[1:]}/season/{season_number}/credits",
        params={"api_key": TMDB_api_key},
    )
    return credits


async def getTvSeasonCountCached(media_id: str) -> dict:
    if media_id[0] != tv_id_identifier:
        return {"status": "error", "message": "Invalid media id for TV season count"}
    
    raw_media_data = await getMediaUsingIDRawCached(media_id, tv_id_identifier)
    season_count = raw_media_data.get("number_of_seasons", 0)
    result = {"season_count": season_count}
    return result


SEASON_COUNT_CACHE = cache_lock_logic.CACHE_TTL(maxsize=10000, ttl=hourCalculator(24))
SEASON_COUNT_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getTvSeasonCount(media_id: str) -> int:
    """
    Gets he season count for a TV show from TMDB API
    """
    args = (media_id,)
    key = (media_id,)
    result = await cache_lock_logic.cacheLockLogicTTL(
        args=args,
        key=key,
        CACHE=SEASON_COUNT_CACHE,
        LOCK=SEASON_COUNT_LOCK,
        function=getTvSeasonCountCached,
    )

    if "season_count" in result:
        return result["season_count"]

    return result







async def getSeasonInfoCached(tv_id: str, season_number: int) -> dict:
    if tv_id[0] != tv_id_identifier:
        return {"status": "error", "message": "Invalid media id for TV season info"}
    season_info = await sendAsyncHttpRequestGet(
        httpx_controller_client,
        f"{TMDB_base_api_url}/{TMDB_id_search_tv}/{tv_id[1:]}/season/{season_number}",
        params={"api_key": TMDB_api_key},
    )
    return season_info

SEASON_INFO_CACHE = cache_lock_logic.CACHE_LRU(maxsize=10000)
SEASON_INFO_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getSeasonInfo(tv_id: str, season_number: int) -> dict:
    """
    Gets the season information for the given tv show from TMDB API
    """
    args = (tv_id, season_number)
    key = (tv_id, season_number)
    season_info = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=SEASON_INFO_CACHE,
        LOCK=SEASON_INFO_LOCK,
        function=getSeasonInfoCached,
    )
    return season_info


async def getTvRuntimeFromTMDBCached(media_id: str) -> dict:
    """
    Gets the runtime information for the given media from TMDB API
    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, PLEASE CALL WITH cache_lock_logic.cacheLockLogicLRU TO ENSURE PROPER EFFICIENCY AND FUNCTIONALITY
    """

    raw_media_data = await getMediaUsingIDRawCached(media_id, tv_id_identifier)
    season_count = raw_media_data.get("number_of_seasons", 0)

    total_runtime = 0

    if season_count > 0:
        season_tasks = [
            getSeasonInfo(media_id, i) for i in range(1, season_count + 1)
        ]
        season_infos = await asyncio.gather(*season_tasks, return_exceptions=True)

        for season_info in season_infos:
            if isinstance(season_info, Exception):
                continue

            episodes = season_info.get("episodes", [])
            if not isinstance(episodes, list):
                continue

            for episode in episodes:
                episode_runtime = episode.get(
                    "runtime", 0
                )  # TODO: should we just calculate by average ep time * episode amount?
                if episode_runtime:
                    total_runtime += episode_runtime

    result = {"total_runtime": total_runtime}
    return result


async def getMovieRuntimeFromTMDBCached(media_id: str) -> dict:
    """
    Gets the runtime information for the given media from TMDB API
    """

    raw_media_data = await getMediaUsingIDRawCached(media_id, movie_id_identifier)
    runtime = raw_media_data.get("runtime", 0)

    result = {"total_runtime": runtime}
    return result



RUNTIME_CACHE = cache_lock_logic.CACHE_LRU(maxsize=10000)
RUNTIME_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getRuntime(media_id: str) -> dict:
    """
    Gets the runtime information for the given media from TMDB API
    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, PLEASE CALL WITH cache_lock_logic.cacheLockLogicLRU TO ENSURE PROPER EFFICIENCY AND FUNCTIONALITY
    """
    media_type = media_id[0]
    if media_type == movie_id_identifier:
        args = (media_id,)
        key = (media_id,)
        result = await cache_lock_logic.cacheLockLogicLRU(
            args=args,
            key=key,
            CACHE=RUNTIME_CACHE,
            LOCK=RUNTIME_LOCK,
            function=getMovieRuntimeFromTMDBCached,
        )
        return result

    elif media_type == tv_id_identifier:
        args = (media_id,)
        key = (media_id,)
        result = await cache_lock_logic.cacheLockLogicLRU(
            args=args,
            key=key,
            CACHE=RUNTIME_CACHE,
            LOCK=RUNTIME_LOCK,
            function=getTvRuntimeFromTMDBCached,
        )

        return result
    else:
        return None




async def getCreditCached(media_id: str) -> dict:
    """
    Gets the credits (director/creator) information for the given media from TMDB API
    """

    media_type = media_id[0]

    media_id_search = ""
    if media_type == movie_id_identifier:
        media_id_search = TMDB_id_search_movie
    elif media_type == tv_id_identifier:
        media_id_search = TMDB_id_search_tv
    else:
        return {}

    credits = await sendAsyncHttpRequestGet(
        httpx_controller_client,
        f"{TMDB_base_api_url}/{media_id_search}/{media_id[1:]}/credits",
        params={"api_key": TMDB_api_key},
    )

    return credits


CREDITS_CACHE = cache_lock_logic.CACHE_LRU(maxsize=10000)
CREDITS_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getCredits(media_id: str) -> dict:
    """
    Gets the credits (director/creator) information for the given media from TMDB API
    """
    args = (media_id,)
    key = (media_id,)
    credits = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=CREDITS_CACHE,
        LOCK=CREDITS_LOCK,
        function=getCreditCached,
    )

    return credits





# =====================================================================================
# Media Retrieval functions
# =====================================================================================

async def getMediaUsingIDRawCached(media_id: str, request_type: str) -> dict:
    """
    Gets the raw media data from TMDB API for a specific media id and type.
    """
    id_search_endpoint = ""
    # if movie search
    if request_type == "m":
        id_search_endpoint = TMDB_id_search_movie
    # if tv seach
    elif request_type == "t":
        id_search_endpoint = TMDB_id_search_tv

    media_data = await sendAsyncHttpRequestGet(
        httpx_controller_client,
        f"{TMDB_base_api_url}/{id_search_endpoint}/{media_id[1:]}",
        params={"api_key": TMDB_api_key},
    )
    return media_data

async def getMediaUsingIDCached(media_id: str, request_type: str) -> dict:
    """
    searches for a movie or tv show using the given id in the TMDB API and returns the cleaned media data in our standard format. If no media is found, returns an empty dictionary.


    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, PLEASE CALL WITH cache_lock_logic.cacheLockLogicTTL TO ENSURE PROPER EFFICIENCY AND FUNCTIONALITY
    """

    # if movie search
    if request_type == "m":
        cleanerMethod = datacleaning.cleanMovieData
    # if tv seach
    elif request_type == "t":
        cleanerMethod = datacleaning.cleanTvData

    raw_media_data = await getMediaUsingIDRawCached(media_id, request_type)

    credits, runtime_info = await asyncio.gather(
        getCredits(media_id),
        getRuntime(media_id=media_id),
    )

    cleaned_media = cleanerMethod(raw_media_data, credits, runtime_info)

    # store result in cache
    return cleaned_media


ID_SEARCH_CACHE = cache_lock_logic.CACHE_LRU(maxsize=1000)
ID_SEARCH_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getMediaUsingID(media_id: str, request_type: str) -> dict:
    """
    searches for a movie or tv show using the given id in the TMDB API and returns the cleaned media data in our standard format. If no media is found, returns an empty dictionary.
    """
    args = (media_id, request_type)
    key = (media_id, request_type)
    result = await cache_lock_logic.cacheLockLogicTTL(
        args=args,
        key=key,
        CACHE=ID_SEARCH_CACHE,
        LOCK=ID_SEARCH_LOCK,
        function=getMediaUsingIDCached,
    )
    return result


async def getMediaUsingSearchCached(
    title: str, request_amount: int, request_type: str
) -> list:
    """
    searches for movies or tv shows using the given title in the TMDB API and returns a list of cleaned media data in our standard format that fit the search criteria. If no media is found, returns an empty list.


    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, PLEASE CALL WITH cache_lock_logic.cacheLockLogicTTL TO ENSURE PROPER EFFICIENCY AND FUNCTIONALITY
    """
    # clean input for generality
    title = datacleaning.cleanUserInput(title)

    search_endpoint = ""
    # if movie search
    if request_type == "m":
        search_endpoint = TMDB_search_movie
        cleanerMethod = datacleaning.cleanMovieData
        checkValidMediaMethod = datacleaning.checkValidMovie
    # if tv seach
    elif request_type == "t":
        search_endpoint = TMDB_search_tv
        cleanerMethod = datacleaning.cleanTvData
        checkValidMediaMethod = datacleaning.checkValidTv

    # TMDB uses 1 based indexing for pages
    page = 1
    result = []

    # getting all media that fit the search criteria from the TMDB API
    while len(result) < request_amount:
        data = await sendAsyncHttpRequestGet(
            httpx_controller_client,
            f"{TMDB_base_api_url}/{search_endpoint}",
            params={
                "api_key": TMDB_api_key,
                "query": title,
                "language": "en-US",
                "page": page,
                "include_adult": False,
            },
        )

        # no results
        if not data["results"]:
            break

        async def enrich_media(media: dict):
            media_identifier = f"{request_type}{media['id']}"
            credits, runtime_info = await asyncio.gather(
                getCredits(media_identifier),
                getRuntime(media_identifier),
            )
            cleaned_media = cleanerMethod(media, credits, runtime_info)
            if not checkValidMediaMethod(cleaned_media):
                return None
            return cleaned_media

        enriched_page = await asyncio.gather(
            *[enrich_media(media) for media in data["results"]],
            return_exceptions=True,
        )

        for cleaned_media in enriched_page:
            if isinstance(cleaned_media, Exception) or cleaned_media is None:
                continue

            result.append(cleaned_media)

            # if found enough results
            if len(result) >= request_amount:
                break

        page += 1

        # if no more pages or checked max number of pages
        if page > data["total_pages"] or page > max_number_of_pages:
            break

    logTimeCheck("getMediaFromTMDB SEARCH AFTER", MEDIA_API_TIME_CHECK)
    return result



SEARCH_CACHE = cache_lock_logic.CACHE_TTL(maxsize=10000, ttl=hourCalculator(3))
SEARCH_LOCK = cache_lock_logic.LOCK(asyncio.Lock)
async def getMediaUsingSearch(title: str, request_amount: int, request_type: str) -> list:
    """
    searches for movies or tv shows using the given title in the TMDB API and returns a list of cleaned media data in our standard format that fit the search criteria. If no media is found, returns an empty list.
    """
    # TODO: CLEAN TITLE?
    args = (title, request_amount, request_type)
    key = (title, request_amount, request_type)
    result = await cache_lock_logic.cacheLockLogicTTL(
        args=args,
        key=key,
        CACHE=SEARCH_CACHE,
        LOCK=SEARCH_LOCK,
        function=getMediaUsingSearchCached,
    )
    return result






