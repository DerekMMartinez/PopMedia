from fastapi import FastAPI
from datetime import datetime
from collections import Counter

import standardmedia

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


from httpx_logic import httpx_annual_recap_client, sendAsyncHttpRequestGet

CONTROLLER_PORT = "8000"
OUR_SERVER_API_URL = "http://localhost"

person_picture_base_url = "https://image.tmdb.org/t/p/original"

app = FastAPI()

month_dict = {
    1: "January",
    2: "February",
    3: "March",
    4: "April",
    5: "May",
    6: "June",
    7: "July",
    8: "August",
    9: "September",
    10: "October",
    11: "November",
    12: "December",
}


async def getUserReviewMedia(uid: str) -> list:
    user_review_media_list = await sendAsyncHttpRequestGet(
        client=httpx_annual_recap_client,
        url=f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getUserMediaReviews",
        params={"request_uid": uid, "target_uid": uid, "type": "a"},
    )

    return user_review_media_list


async def getCreditsForTMDB(media: dict) -> dict:
    credits = await sendAsyncHttpRequestGet(
        client=httpx_annual_recap_client,
        url=f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getCreditsForMedia",
        params={"media_id": media[id_key]},
    )

    return credits


async def getCreditsForSeasonTMDB(media_id: str, season_number: int) -> dict:
    credits = await sendAsyncHttpRequestGet(
        client=httpx_annual_recap_client,
        url=f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getCreditsForMediaSeason",
        params={"media_id": media_id, "season_number": season_number},
    )

    return credits


async def getSeasonReviews(uid: str, tv_id: int) -> list:
    season_reviews = await sendAsyncHttpRequestGet(
        client=httpx_annual_recap_client,
        url=f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getSeasonReviewsForUser",
        params={"uid": uid, "tv_id": tv_id},
    )

    return season_reviews


async def getSeasonInfoForTv(tmdb_id: str, season_number: int) -> dict:
    season_info = await sendAsyncHttpRequestGet(
        client=httpx_annual_recap_client,
        url=f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getSeasonInfo",
        params={"media_id": tmdb_id, "season_number": season_number},
    )

    return season_info


async def getRuntimeOfSeason(season_info: dict) -> int:
    episodes = season_info["episodes"]
    total_runtime = 0

    for episode in episodes:
        if episode["runtime"] is not None:
            total_runtime += episode["runtime"]

    return total_runtime


def minutesToHours(minutes: int) -> float:
    hours = float(minutes) / 60
    return hours


def parseFinishedOn(finished_on_value: str) -> datetime:
    """
    Parse finished_on values that may arrive as either YYYY-MM-DD
    or full ISO datetime strings (with optional timezone).
    """
    try:
        return datetime.strptime(finished_on_value, "%Y-%m-%d")
    except ValueError:
        return datetime.fromisoformat(finished_on_value.replace("Z", "+00:00"))


def getValidReviewMediaByYear(review_media_list: list, year: str) -> list:
    """
    Filters the review media list to only include media that were finished in the specified year.
    """
    valid_review_media = []
    for review_media in review_media_list:
        review = review_media[0]
        finished_on = parseFinishedOn(review["finished_on"])
        if finished_on.year == int(year):
            valid_review_media.append(review_media)

    return valid_review_media


async def getPersonPictureUrlTMDB(data: dict) -> str:
    """
    gets the person's picture url from TMDB if it exists, otherwise returns the media_invalid_str_key
    """
    if "profile_path" in data and data["profile_path"]:
        return f"{person_picture_base_url}{data['profile_path']}"
    else:
        return media_invalid_str_key


async def getBadgesEarnedInYear(uid: str, year: str) -> list:
    badges_earned = await sendAsyncHttpRequestGet(
        client=httpx_annual_recap_client,
        url=f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getBadgesEarnedInYear",
        params={"uid": uid, "year": year},
    )

    return badges_earned


async def ß(π: dict) -> list:
    """
    NOTICE: çø¨˜†´®†øπ†˙®´´©´†¥åøˆˆˆˆ
    """
    _ = ("", 0)
    __ = ("", 0)
    ___ = ("", 0)

    for œ, ø in π.items():
        if ø > _[1]:
            ___ = __
            __ = _
            _ = (œ, ø)
        elif ø > __[1]:
            ___ = __
            __ = (œ, ø)
        elif ø > ___[1]:
            ___ = (œ, ø)

    return (_, __, ___)


def getFavoriteMedia(review_media_list: list) -> list:
    """
    gets the favorite media from the media list based on the overall rating key.

    returns a list of the top 3 favorite media.
    """
    sorted_media = sorted(
        review_media_list, key=lambda x: x[0][review_rating_key], reverse=True
    )
    result = sorted_media[:3]
    size = len(sorted_media)
    if len(sorted_media) > 3:
        for i in range(3, size):
            if sorted_media[i][0][review_rating_key] == result[2][0][review_rating_key]:
                result.append(sorted_media[i])
            else:
                break

    return result


async def getBookData(review_book_list: list) -> dict:
    """ """
    book_data = {
        "books_read_per_month": [0 for _ in range(12)],
        "total_books_read": 0,
        "pages_read_per_month": [0.0 for _ in range(12)],
        "total_pages_read": 0,
        "creators": {},
        "weighted_creators": {},
        "genres": Counter(),
        "favorite_books": [],
    }

    for review_book in review_book_list:
        review = review_book[0]
        book = review_book[1]

        finished_on = parseFinishedOn(review["finished_on"])
        month_num = finished_on.month

        book_data["genres"].update(book[genres_key])

        book_data["books_read_per_month"][month_num - 1] += 1
        book_data["total_books_read"] += 1

        book_data["pages_read_per_month"][month_num - 1] += book[media_length_key]
        book_data["total_pages_read"] += book[media_length_key]

        if not book[creator_key] == media_invalid_str_key:
            # unweighted creator count
            if book[creator_key].lower() not in book_data["creators"]:
                book_data["creators"][book[creator_key].lower()] = 0

            book_data["creators"][book[creator_key].lower()] += 1

            # weighted creator count
            if book[creator_key].lower() not in book_data["weighted_creators"]:
                book_data["weighted_creators"][book[creator_key].lower()] = 0

            book_data["weighted_creators"][book[creator_key].lower()] += review[
                review_rating_key
            ]

    book_data["favorite_books"] = getFavoriteMedia(review_book_list)

    return book_data


# TODO: set designer and makeup artsit?
async def getMovieData(user_review_movie_list: list) -> tuple:
    movie_data = {
        "movie_per_month": [0 for _ in range(12)],
        "total_movies_watched": 0,
        "watchtime_per_month": [0.0 for _ in range(12)],
        "total_watchtime": 0.0,
        "actors": {},
        "weighted_actors": {},
        "directors": {},
        "weighted_directors": {},
        "composers": {},
        "weighted_composers": {},
        "cinematographers": {},
        "weighted_cinematographers": {},
        "stunt_coordinators": {},
        "weighted_stunt_coordinators": {},
        "castors": {},
        "weighted_castors": {},
        "costumer_designers": {},
        "weighted_costumer_designers": {},
        "people_pictures": {},
        "genres": Counter(),
        "favorite_movies": [],
    }

    for review_movie in user_review_movie_list:
        review = review_movie[0]
        movie = review_movie[1]
        finished_on = parseFinishedOn(review["finished_on"])
        month_num = finished_on.month

        movie_data["movie_per_month"][month_num - 1] += 1
        movie_data["total_movies_watched"] += 1

        movie_data["watchtime_per_month"][month_num - 1] += movie[media_length_key]
        movie_data["total_watchtime"] += minutesToHours(movie[media_length_key])

        credit_data = await getCreditsForTMDB(movie)
        cast = credit_data["cast"]
        crew = credit_data["crew"]

        movie_data["genres"].update(movie[genres_key])

        for actor in cast:
            name = actor["name"].lower()
            # unweighted count
            if name not in movie_data["actors"]:
                movie_data["actors"][name] = 0
            movie_data["actors"][name] += 1

            # weighted count
            if actor["name"].lower() not in movie_data["weighted_actors"]:
                movie_data["weighted_actors"][name] = 0
            movie_data["weighted_actors"][name] += review[review_rating_key]

            movie_data["people_pictures"][name] = await getPersonPictureUrlTMDB(actor)

        for crew_member in crew:
            job = crew_member["job"].lower()
            name = crew_member["name"].lower()

            standardized_job = ""
            if job == "director":
                standardized_job = "directors"

            if job == "original music composer":
                standardized_job = "composers"

            if job == "director of photography":
                standardized_job = "cinematographers"

            if job == "stunt coordinator":
                standardized_job = "stunt_coordinators"

            if job == "casting":
                standardized_job = "castors"

            if job == "costume design":
                standardized_job = "costumer_designers"

            if standardized_job != "":
                # unweighted count
                if name not in movie_data[standardized_job]:
                    movie_data[standardized_job][name] = 0
                movie_data[standardized_job][name] += 1

                # weighted count
                if name not in movie_data[f"weighted_{standardized_job}"]:
                    movie_data[f"weighted_{standardized_job}"][name] = 0
                movie_data[f"weighted_{standardized_job}"][name] += review[
                    review_rating_key
                ]

            movie_data["people_pictures"][name] = await getPersonPictureUrlTMDB(
                crew_member
            )

    movie_data["favorite_movies"] = getFavoriteMedia(user_review_movie_list)
    return movie_data


async def getTvData(user_review_tv_list: list) -> tuple:
    tv_data = {
        "tv_per_month": [0 for _ in range(12)],
        "total_tv_watched": 0,
        "watchtime_per_month": [0.0 for _ in range(12)],
        "total_watchtime": 0.0,
        "actors": {},
        "weighted_actors": {},
        "people_pictures": {},
        "genres": Counter(),
        "favorite_tv": [],
    }

    for review_tv in user_review_tv_list:
        review = review_tv[0]

        season_reviews = await getSeasonReviews(
            uid=review[review_uid_key], tv_id=review["id"]
        )
        number_of_season_reviews = len(season_reviews)

        tv = review_tv[1]
        season_count = tv[season_count_key]
        finished_on = parseFinishedOn(review["finished_on"])
        month_num = finished_on.month

        tv_data["genres"].update(tv[genres_key])

        # collecting per season data
        if number_of_season_reviews > 0:
            for season_review in season_reviews:
                finished_on = parseFinishedOn(season_review["finished_on"])
                month_num = finished_on.month
                season_rating = season_review["rating"]

                season_info = await getSeasonInfoForTv(
                    tmdb_id=tv[id_key], season_number=season_review["season_number"]
                )
                season_runtime = await getRuntimeOfSeason(season_info)
                hours_season_runtime = minutesToHours(season_runtime)

                tv_data["tv_per_month"][month_num - 1] += 1
                tv_data["total_tv_watched"] += 1

                tv_data["watchtime_per_month"][month_num - 1] += hours_season_runtime
                tv_data["total_watchtime"] += hours_season_runtime

                credit_data = await getCreditsForSeasonTMDB(
                    media_id=tv[id_key], season_number=season_review["season_number"]
                )
                cast = credit_data["cast"]

                # collecting cast data
                for actor in cast:
                    name = actor["name"].lower()
                    # unweighted count
                    if name not in tv_data["actors"]:
                        tv_data["actors"][name] = 0
                    tv_data["actors"][name] += 1

                    # weighted count
                    if name not in tv_data["weighted_actors"]:
                        tv_data["weighted_actors"][name] = 0

                    tv_data["weighted_actors"][name] += (
                        review[review_rating_key] / number_of_season_reviews
                    )

                    tv_data["people_pictures"][name] = await getPersonPictureUrlTMDB(
                        actor
                    )

        else:
            tv_data["tv_per_month"][month_num - 1] += season_count
            tv_data["total_tv_watched"] += season_count

            tv_data["watchtime_per_month"][month_num - 1] += minutesToHours(
                tv[media_length_key]
            )
            tv_data["total_watchtime"] += minutesToHours(tv[media_length_key])

            credit_data = await getCreditsForTMDB(tv)
            cast = credit_data["cast"]

            for actor in cast:
                name = actor["name"].lower()
                # unweighted count
                if name not in tv_data["actors"]:
                    tv_data["actors"][name] = 0
                tv_data["actors"][name] += 1

                # weighted count
                if name not in tv_data["weighted_actors"]:
                    tv_data["weighted_actors"][name] = 0

                tv_data["weighted_actors"][name] += review[review_rating_key]

                tv_data["people_pictures"][name] = await getPersonPictureUrlTMDB(actor)

    tv_data["favorite_tv"] = getFavoriteMedia(user_review_tv_list)
    return tv_data


async def seperateReviewMediaByType(user_review_media_list) -> dict:

    seperated_result = {
        book_id_identifier: [],
        movie_id_identifier: [],
        tv_id_identifier: [],
    }

    for review_media in user_review_media_list:
        media_type = review_media[1][id_key][0]

        seperated_result[media_type].append(review_media)

    return seperated_result


async def getRecapDataForUserCached(uid: str, year: str) -> dict:

    print(
        "================================= RECAP NOT CACHED ===================================="
    )

    user_review_media_list = await getUserReviewMedia(uid=uid)

    yearly_review_media_list = getValidReviewMediaByYear(
        review_media_list=user_review_media_list, year=year
    )

    seperated_reviews_by_type = await seperateReviewMediaByType(
        user_review_media_list=yearly_review_media_list
    )

    user_review_book_list = seperated_reviews_by_type[book_id_identifier]
    user_review_movie_list = seperated_reviews_by_type[movie_id_identifier]
    user_review_tv_list = seperated_reviews_by_type[tv_id_identifier]

    book_data = await getBookData(user_review_book_list)
    movie_data = await getMovieData(user_review_movie_list)
    tv_data = await getTvData(user_review_tv_list)

    recap_data = {}

    # book data collection =========================================================================
    recap_data["books_read_per_month"] = book_data["books_read_per_month"]
    recap_data["total_books_read"] = book_data["total_books_read"]

    recap_data["pages_read_per_month"] = book_data["pages_read_per_month"]
    recap_data["total_pages_read"] = book_data["total_pages_read"]

    recap_data["top_3_authors"] = await ß(book_data["creators"])
    if not recap_data["top_3_authors"]:
        recap_data["top_3_authors"] = [("", 0), ("", 0), ("", 0)]
    recap_data["top_3_weighted_authors"] = await ß(book_data["weighted_creators"])
    if not recap_data["top_3_weighted_authors"]:
        recap_data["top_3_weighted_authors"] = [("", 0), ("", 0), ("", 0)]
    recap_data["favorite_books"] = book_data["favorite_books"]

    # movie data collection ==================================================================
    # TODO: collect the media said actors were in?
    recap_data["movie_per_month"] = movie_data["movie_per_month"]
    recap_data["movie_total_watched"] = movie_data["total_movies_watched"]

    recap_data["movie_watchtime_per_month"] = movie_data["watchtime_per_month"]
    recap_data["movie_total_watchtime"] = movie_data["total_watchtime"]

    # top three movies
    recap_data["movie_top_3_actors"] = await ß(movie_data["actors"])
    recap_data["movie_top_3_weighted_actors"] = await ß(movie_data["weighted_actors"])
    if not recap_data["movie_top_3_actors"]:
        recap_data["movie_top_3_actors"] = [("", 0), ("", 0), ("", 0)]
    if not recap_data["movie_top_3_weighted_actors"]:
        recap_data["movie_top_3_weighted_actors"] = [("", 0), ("", 0), ("", 0)]

    recap_data["movie_top_3_directors"] = await ß(movie_data["directors"])
    recap_data["movie_top_3_weighted_directors"] = await ß(
        movie_data["weighted_directors"]
    )

    recap_data["movie_top_3_composers"] = await ß(movie_data["composers"])
    recap_data["movie_top_3_weighted_composers"] = await ß(
        movie_data["weighted_composers"]
    )

    recap_data["movie_top_3_cinematographers"] = await ß(movie_data["cinematographers"])
    recap_data["movie_top_3_weighted_cinematographers"] = await ß(
        movie_data["weighted_cinematographers"]
    )

    recap_data["movie_top_3_stunt_coordinators"] = await ß(
        movie_data["stunt_coordinators"]
    )
    recap_data["movie_top_3_weighted_stunt_coordinators"] = await ß(
        movie_data["weighted_stunt_coordinators"]
    )

    recap_data["movie_top_3_castors"] = await ß(movie_data["castors"])
    recap_data["movie_top_3_weighted_castors"] = await ß(movie_data["weighted_castors"])

    recap_data["movie_top_3_costumer_designers"] = await ß(
        movie_data["costumer_designers"]
    )
    recap_data["movie_top_3_weighted_costumer_designers"] = await ß(
        movie_data["weighted_costumer_designers"]
    )

    recap_data["movie_people_pictures"] = movie_data["people_pictures"]
    recap_data["favorite_movies"] = movie_data["favorite_movies"]

    # tv data collection =========================================================================
    recap_data["tv_per_month"] = tv_data["tv_per_month"]
    recap_data["tv_total_watched"] = tv_data["total_tv_watched"]

    recap_data["tv_watchtime_per_month"] = tv_data["watchtime_per_month"]
    recap_data["tv_total_watchtime"] = tv_data["total_watchtime"]

    # top three actors
    recap_data["tv_top_3_actors"] = await ß(tv_data["actors"])
    if not recap_data["tv_top_3_actors"]:
        recap_data["tv_top_3_actors"] = [("", 0), ("", 0), ("", 0)]
    recap_data["tv_top_3_weighted_actors"] = await ß(tv_data["weighted_actors"])
    if not recap_data["tv_top_3_weighted_actors"]:
        recap_data["tv_top_3_weighted_actors"] = [("", 0), ("", 0), ("", 0)]

    recap_data["tv_people_pictures"] = tv_data["people_pictures"]

    recap_data["favorite_tv"] = tv_data["favorite_tv"]

    # other data collection =========================================================================
    recap_data["total_watchtime"] = round(
        recap_data["tv_total_watchtime"] + recap_data["movie_total_watchtime"], 2
    )
    recap_data["badges_earned"] = await getBadgesEarnedInYear(uid=uid, year=year)

    genres_counter = Counter()
    genres_counter.update(book_data["genres"])
    genres_counter.update(movie_data["genres"])
    genres_counter.update(tv_data["genres"])
    top_genres_scores = genres_counter.most_common(5)

    recap_data["top_5_genres"] = [genre for genre, count in top_genres_scores]

    return recap_data


from cachetools import TTLCache
from collections import defaultdict
import asyncio
import cache_lock_logic


def hourCalculator(minues: float) -> int:
    return int(minues * 60 * 60)


def minuteCalculator(minutes: float) -> int:
    return int(minutes * 60)


RECAP_CACHE = TTLCache(
    maxsize=10000, ttl=hourCalculator(3)
)  # Cache for book search results, expires after 15 minutes since book data can update more frequently
RECAP_LOCK = defaultdict(asyncio.Lock)


@app.get("/getRecapDataForUser")
async def getRecapDataForUser(uid: str, year: str) -> dict:
    args = (uid, year)
    key = (uid, year)
    recap_data = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=RECAP_CACHE,
        LOCK=RECAP_LOCK,
        function=getRecapDataForUserCached,
    )
    return recap_data
