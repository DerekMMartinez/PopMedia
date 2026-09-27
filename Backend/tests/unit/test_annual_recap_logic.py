import os
import sys
import types
from unittest.mock import AsyncMock, MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


class DummyFastAPI:
    def get(self, _path):
        def _decorator(fn):
            return fn

        return _decorator


fastapi_mod = types.ModuleType("fastapi")
fastapi_mod.FastAPI = DummyFastAPI
sys.modules["fastapi"] = fastapi_mod

_original_httpx_logic = sys.modules.get("httpx_logic")
sys.modules["httpx_logic"] = types.SimpleNamespace(
    httpx_controller_client=object(),
    httpx_annual_recap_client=object(),
    sendAsyncHttpRequestPost=AsyncMock(),
    sendAsyncHttpRequestGet=AsyncMock(),
)


import annual_recap_logic as ar

if _original_httpx_logic is not None:
    sys.modules["httpx_logic"] = _original_httpx_logic
else:
    sys.modules.pop("httpx_logic", None)


def _review(uid, media_id, rating, finished_on, tv_id=0):
    return {
        ar.review_uid_key: uid,
        ar.review_media_id_key: media_id,
        ar.review_rating_key: rating,
        ar.review_finished_on_key: finished_on,
        "finished_on": finished_on,
        "id": tv_id,
    }


def _media(media_id, creator=None, length=100, season_count=1):
    creator_value = ar.media_invalid_str_key if creator is None else creator
    return {
        ar.id_key: media_id,
        ar.creator_key: creator_value,
        ar.media_length_key: length,
        ar.season_count_key: season_count,
        ar.genres_key: [],
    }


def test_parse_finished_on_and_year_filtering():
    assert ar.parseFinishedOn("2025-02-14").year == 2025
    assert ar.parseFinishedOn("2025-03-01T10:00:00Z").year == 2025

    media_list = [
        [{"finished_on": "2025-01-01"}, {ar.id_key: "m1"}],
        [{"finished_on": "2024-01-01"}, {ar.id_key: "m2"}],
    ]
    filtered = ar.getValidReviewMediaByYear(media_list, "2025")
    assert len(filtered) == 1
    assert filtered[0][1][ar.id_key] == "m1"


async def test_http_wrapper_functions(monkeypatch):
    mock_get = AsyncMock(return_value=[{"ok": True}])
    monkeypatch.setattr(ar, "sendAsyncHttpRequestGet", mock_get)

    assert await ar.getUserReviewMedia("u1") == [{"ok": True}]
    assert await ar.getCreditsForTMDB({ar.id_key: "m1"}) == [{"ok": True}]
    assert await ar.getCreditsForSeasonTMDB("t1", 2) == [{"ok": True}]
    assert await ar.getSeasonReviews("u1", 77) == [{"ok": True}]
    assert await ar.getSeasonInfoForTv("t1", 1) == [{"ok": True}]


async def test_get_runtime_of_season():
    season_info = {"episodes": [{"runtime": 45}, {"runtime": None}, {"runtime": 30}]}
    assert await ar.getRuntimeOfSeason(season_info) == 75


async def test_get_person_picture_url_tmdb():
    assert (
        await ar.getPersonPictureUrlTMDB({"profile_path": "/abc.jpg"})
        == f"{ar.person_picture_base_url}/abc.jpg"
    )
    assert await ar.getPersonPictureUrlTMDB({}) == ar.media_invalid_str_key


async def test_top3_function_with_unicode_name():
    top3_fn = getattr(ar, "ß")
    top = await top3_fn({"a": 10, "b": 7, "c": 3, "d": 2})
    assert top[0] == ("a", 10)
    assert top[1] == ("b", 7)
    assert top[2] == ("c", 3)


async def test_get_book_data_counts_and_weighted_creators():
    reviews = [
        [
            _review("u1", "b1", 4, "2025-01-10"),
            _media("b1", creator="Author A", length=300),
        ],
        [
            _review("u1", "b2", 2, "2025-01-11"),
            _media("b2", creator="Author A", length=200),
        ],
        [_review("u1", "b3", 5, "2025-02-01"), _media("b3", creator=None, length=150)],
    ]

    result = await ar.getBookData(reviews)
    assert result["books_read_per_month"][0] == 2
    assert result["books_read_per_month"][1] == 1
    assert result["total_books_read"] == 3
    assert result["pages_read_per_month"][0] == 500
    assert result["total_pages_read"] == 650
    assert result["creators"]["author a"] == 2
    assert result["weighted_creators"]["author a"] == 6


async def test_get_movie_data_with_all_job_buckets(monkeypatch):
    reviews = [[_review("u1", "m1", 4, "2025-03-20"), _media("m1", length=120)]]

    credit_data = {
        "cast": [{"name": "Actor One", "profile_path": "/actor.jpg"}],
        "crew": [
            {"name": "Dir", "job": "Director", "profile_path": "/dir.jpg"},
            {
                "name": "Comp",
                "job": "Original Music Composer",
                "profile_path": "/comp.jpg",
            },
            {
                "name": "Cine",
                "job": "Director of Photography",
                "profile_path": "/cine.jpg",
            },
            {"name": "Stunt", "job": "Stunt Coordinator", "profile_path": "/stunt.jpg"},
            {"name": "Cast", "job": "Casting", "profile_path": "/cast.jpg"},
            {
                "name": "Costume",
                "job": "Costume Design",
                "profile_path": "/costume.jpg",
            },
            {"name": "Other", "job": "Writer", "profile_path": "/other.jpg"},
        ],
    }

    monkeypatch.setattr(ar, "getCreditsForTMDB", AsyncMock(return_value=credit_data))
    monkeypatch.setattr(
        ar,
        "getPersonPictureUrlTMDB",
        AsyncMock(side_effect=lambda d: f"pic:{d['name']}"),
    )

    result = await ar.getMovieData(reviews)
    assert result["movie_per_month"][2] == 1
    assert result["total_movies_watched"] == 1
    assert result["watchtime_per_month"][2] == 120
    assert result["total_watchtime"] == 2.0
    assert result["actors"]["actor one"] == 1
    assert result["weighted_actors"]["actor one"] == 4
    assert result["directors"]["dir"] == 1
    assert result["weighted_directors"]["dir"] == 4
    assert result["composers"]["comp"] == 1
    assert result["cinematographers"]["cine"] == 1
    assert result["stunt_coordinators"]["stunt"] == 1
    assert result["castors"]["cast"] == 1
    assert result["costumer_designers"]["costume"] == 1
    assert result["people_pictures"]["other"] == "pic:Other"


async def test_get_tv_data_with_season_reviews(monkeypatch):
    review = _review("u1", "t1", 5, "2025-04-01", tv_id=101)
    tv = _media("t1", length=50, season_count=2)

    monkeypatch.setattr(
        ar,
        "getSeasonReviews",
        AsyncMock(
            return_value=[
                {"season_number": 1, "finished_on": "2025-04-01", "rating": 4},
                {"season_number": 2, "finished_on": "2025-05-01", "rating": 5},
            ]
        ),
    )
    monkeypatch.setattr(
        ar,
        "getSeasonInfoForTv",
        AsyncMock(return_value={"episodes": [{"runtime": 30}, {"runtime": 20}]}),
    )
    monkeypatch.setattr(ar, "getRuntimeOfSeason", AsyncMock(return_value=50))
    monkeypatch.setattr(
        ar,
        "getCreditsForSeasonTMDB",
        AsyncMock(
            return_value={"cast": [{"name": "TV Actor", "profile_path": "/x.jpg"}]}
        ),
    )
    monkeypatch.setattr(
        ar, "getPersonPictureUrlTMDB", AsyncMock(return_value="pic:tvactor")
    )

    result = await ar.getTvData([[review, tv]])
    assert result["tv_per_month"][3] == 1
    assert result["tv_per_month"][4] == 1
    assert result["total_tv_watched"] == 2
    assert result["watchtime_per_month"][3] == 50 / 60
    assert result["watchtime_per_month"][4] == 50 / 60
    assert result["actors"]["tv actor"] == 2
    assert result["weighted_actors"]["tv actor"] == 5


# async def test_get_tv_data_without_season_reviews(monkeypatch):
#     review = _review("u1", "t1", 3, "2025-06-01", tv_id=101)
#     tv = _media("t1", length=40, season_count=3)

#     monkeypatch.setattr(ar, "getSeasonReviews", AsyncMock(return_value=[]))
#     monkeypatch.setattr(
#         ar,
#         "getCreditsForTMDB",
#         AsyncMock(
#             return_value={
#                 "cast": [{"name": "Fallback Actor", "profile_path": "/y.jpg"}]
#             }
#         ),
#     )
#     monkeypatch.setattr(
#         ar, "getPersonPictureUrlTMDB", AsyncMock(return_value="pic:fallback")
#     )

#     result = await ar.getTvData([[review, tv]])
#     assert result["tv_per_month"][5] == 0
#     assert result["total_tv_watched"] == 3
#     assert result["watchtime_per_month"][5] == 40 / 60
#     assert result["weighted_actors"]["fallback actor"] == 3


async def test_separate_review_media_by_type():
    grouped = await ar.seperateReviewMediaByType(
        [
            [_review("u", "b1", 1, "2025-01-01"), _media("b1")],
            [_review("u", "m1", 1, "2025-01-01"), _media("m1")],
            [_review("u", "t1", 1, "2025-01-01"), _media("t1")],
        ]
    )
    assert len(grouped[ar.book_id_identifier]) == 1
    assert len(grouped[ar.movie_id_identifier]) == 1
    assert len(grouped[ar.tv_id_identifier]) == 1


async def test_get_recap_data_for_user_orchestrator(monkeypatch):
    sample_reviews = [[_review("u1", "b1", 4, "2025-01-01"), _media("b1")]]

    monkeypatch.setattr(
        ar, "getUserReviewMedia", AsyncMock(return_value=sample_reviews)
    )
    monkeypatch.setattr(
        ar, "getValidReviewMediaByYear", MagicMock(return_value=sample_reviews)
    )
    monkeypatch.setattr(
        ar,
        "seperateReviewMediaByType",
        AsyncMock(
            return_value={
                ar.book_id_identifier: sample_reviews,
                ar.movie_id_identifier: [],
                ar.tv_id_identifier: [],
            }
        ),
    )
    monkeypatch.setattr(
        ar,
        "getBookData",
        AsyncMock(
            return_value={
                "books_read_per_month": [1] + [0] * 11,
                "total_books_read": 1,
                "pages_read_per_month": [250] + [0] * 11,
                "total_pages_read": 250,
                "creators": {"a": 1},
                "weighted_creators": {"a": 4},
                "genres": {},
                "favorite_books": [],
            }
        ),
    )
    monkeypatch.setattr(
        ar,
        "getMovieData",
        AsyncMock(
            return_value={
                "movie_per_month": [0] * 12,
                "total_movies_watched": 0,
                "watchtime_per_month": [0] * 12,
                "total_watchtime": 0,
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
                "genres": {},
                "favorite_movies": [],
            }
        ),
    )
    monkeypatch.setattr(
        ar,
        "getTvData",
        AsyncMock(
            return_value={
                "tv_per_month": [0] * 12,
                "total_tv_watched": 0,
                "watchtime_per_month": [0] * 12,
                "total_watchtime": 0,
                "actors": {},
                "weighted_actors": {},
                "people_pictures": {},
                "genres": {},
                "favorite_tv": [],
            }
        ),
    )

    recap = await ar.getRecapDataForUser("u1", "2025")
    assert recap["total_books_read"] == 1
    assert recap["movie_total_watched"] == 0
    assert recap["tv_total_watched"] == 0
    assert "top_3_authors" in recap
    assert "movie_top_3_directors" in recap
