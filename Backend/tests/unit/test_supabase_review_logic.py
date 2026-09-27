import os
import sys
import types
import asyncio
import inspect
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


class DummyHTTPException(Exception):
    def __init__(self, status_code=None, detail=None):
        super().__init__(detail)
        self.status_code = status_code
        self.detail = detail


fastapi_mod = types.ModuleType("fastapi")
fastapi_mod.FastAPI = MagicMock
fastapi_mod.Depends = MagicMock()
fastapi_mod.HTTPException = DummyHTTPException
fastapi_mod.Response = MagicMock
security_mod = types.ModuleType("fastapi.security")
security_mod.HTTPBearer = MagicMock
security_mod.HTTPAuthorizationCredentials = MagicMock
sys.modules["fastapi"] = fastapi_mod
sys.modules["fastapi.security"] = security_mod

firebase_mod = types.ModuleType("firebase_admin")
firebase_mod.credentials = MagicMock()
firebase_mod.auth = MagicMock()
sys.modules.setdefault("firebase_admin", firebase_mod)

supabase_mod = types.ModuleType("supabase")
supabase_mod.create_client = MagicMock()
supabase_mod.Client = MagicMock()
sys.modules.setdefault("supabase", supabase_mod)

sys.modules.setdefault("dotenv", SimpleNamespace(load_dotenv=MagicMock()))
sys.modules.setdefault("requests", MagicMock())
sys.modules.setdefault("markdown", MagicMock())

sys.modules.setdefault(
    "datacleaning", SimpleNamespace(cleanSupabaseReview=lambda review: review)
)
sys.modules.setdefault(
    "supabase_user_logic",
    SimpleNamespace(
        getUsername=AsyncMock(return_value={"username": "alice"}),
        fetchFollowing=AsyncMock(return_value=[]),
    ),
)
sys.modules.setdefault(
    "external_media_service",
    SimpleNamespace(
        getMediaFromExternalAPIs=AsyncMock(
            return_value=[{"id": "m1", "title": "Movie"}]
        )
    ),
)


class _FakeCache(dict):
    def __init__(self, *args, **kwargs):
        super().__init__()


def _fake_cached(*args, **kwargs):
    def _decorator(fn):
        return fn

    return _decorator


sys.modules.setdefault(
    "cachetools",
    SimpleNamespace(TTLCache=_FakeCache, LRUCache=_FakeCache, cached=_fake_cached),
)
sys.modules.setdefault(
    "cache_lock_logic",
    SimpleNamespace(
        cacheLockLogicLRU=AsyncMock(),
        cacheLockLogicTTL=AsyncMock(),
        repolulateCache=AsyncMock(),
    ),
)

# Avoid real Supabase initialization during import.
sys.modules["supabase_connection_logic"] = SimpleNamespace(supabase=MagicMock())

sys.modules.pop("supabase_review_logic", None)
import supabase_review_logic as srl


def pytest_pyfunc_call(pyfuncitem):
    testfunction = pyfuncitem.obj
    if inspect.iscoroutinefunction(testfunction):
        asyncio.run(testfunction(**pyfuncitem.funcargs))
        return True
    return None


def _response(data=None, count=None):
    return SimpleNamespace(data=([] if data is None else data), count=count)


def _query(response=None, exc=None):
    q = MagicMock()
    for method in ["select", "insert", "update", "delete", "upsert", "eq", "order"]:
        getattr(q, method).return_value = q
    if exc is not None:
        q.execute.side_effect = exc
    else:
        q.execute.return_value = response if response is not None else _response([])
    return q


def _media(media_id):
    return {
        "uid": "u1",
        "media_id": media_id,
        "rating": 4,
        "review_text": "great",
        "review_visibility": "Public",
        "finished_on": "2024-01-15",
        "spoiler": False,
        srl.id_key: media_id,
    }


@pytest.fixture(autouse=True)
def isolate_boundaries(monkeypatch):
    async def _cache_passthrough(*, args, CACHE=None, LOCK=None, function=None):
        return await function(*args)

    monkeypatch.setattr(
        srl.cache_lock_logic,
        "cacheLockLogicLRU",
        AsyncMock(side_effect=_cache_passthrough),
    )
    monkeypatch.setattr(
        srl.cache_lock_logic,
        "cacheLockLogicTTL",
        AsyncMock(side_effect=_cache_passthrough),
    )
    monkeypatch.setattr(
        srl.cache_lock_logic, "repolulateCache", AsyncMock(return_value=None)
    )

    monkeypatch.setattr(
        srl.supabase_user_logic,
        "getUsername",
        AsyncMock(return_value={"username": "alice"}),
    )
    monkeypatch.setattr(
        srl.supabase_user_logic, "fetchFollowing", AsyncMock(return_value=[])
    )
    monkeypatch.setattr(
        srl.external_media_service,
        "getMediaFromExternalAPIs",
        AsyncMock(return_value=[{"id": "m1", "title": "Movie"}]),
    )


def test_time_converters_and_log(capsys):
    assert srl.hourCalculator(2) == 7200
    assert srl.minuteCalculator(1.5) == 90

    srl.logTimeCheck("x", False)
    assert capsys.readouterr().out == ""
    srl.logTimeCheck("x", True)
    assert "x" in capsys.readouterr().out


async def test_sort_review_media_list_by_date_descending():
    a = ({srl.review_finished_on_key: "2024-01-01"}, {"id": 1})
    b = ({srl.review_finished_on_key: "2024-03-01"}, {"id": 2})
    c = ({srl.review_finished_on_key: "2024-02-01"}, {"id": 3})
    sorted_items = await srl.sortReviewMediaListByDate([a, b, c])
    assert [x[0][srl.review_finished_on_key] for x in sorted_items] == [
        "2024-03-01",
        "2024-02-01",
        "2024-01-01",
    ]


async def test_get_book_rating_info_success_and_empty(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(data=[{"id": "b1", "overall_rating": 4.2}])
    )
    monkeypatch.setattr(srl, "supabase", sb)
    assert await srl.getBookRatingInfo("b1") == {"id": "b1", "overall_rating": 4.2}

    sb.table.return_value = _query(_response(data=[]))
    result = await srl.getBookRatingInfo("b2")
    assert result["status"] == "error"


async def test_get_book_rating_info_exception(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(exc=RuntimeError("boom"))
    monkeypatch.setattr(srl, "supabase", sb)
    result = await srl.getBookRatingInfo("b1")
    assert result["status"] == "error"
    assert "boom" in result["message"]


async def test_post_book_rating_info_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(srl, "supabase", sb)
    assert await srl.postBookRatingInfo("b1", 4.5, 10) == {
        "status": "success",
        "table": "book_rating",
    }

    sb.table.return_value = _query(exc=ValueError("db down"))
    result = await srl.postBookRatingInfo("b1", 4.5, 10)
    assert result["status"] == "error"


def test_get_review_count_sums_counts(monkeypatch):
    responses = {
        "book_reviews": _query(_response(count=3)),
        "movie_reviews": _query(_response(count=None)),
        "television_reviews": _query(_response(count=2)),
    }
    sb = MagicMock()
    sb.table.side_effect = lambda name: responses[name]
    monkeypatch.setattr(srl, "supabase", sb)
    assert srl.getReviewCount("u1") == 5


@pytest.mark.parametrize(
    "media_id, expected_table",
    [("m10", "movie_reviews"), ("t20", "television_reviews"), ("b30", "book_reviews")],
)
async def test_post_user_review_cached_table_routing(
    monkeypatch, media_id, expected_table
):
    sb = MagicMock()
    q = _query(_response(data=[{"ok": True}]))
    sb.table.return_value = q
    monkeypatch.setattr(srl, "supabase", sb)

    result = await srl.postUserReviewCached(
        "u1", media_id, 5, "txt", "Public", "2024-01-01", False
    )
    assert result == {"status": "success", "table": expected_table}
    sb.table.assert_called_with(expected_table)


async def test_post_user_review_cached_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(exc=RuntimeError("insert failed"))
    monkeypatch.setattr(srl, "supabase", sb)
    result = await srl.postUserReviewCached(
        "u1", "m1", 3, "x", "Public", "2024-01-01", False
    )
    assert result["status"] == "error"


async def test_post_user_review_success_repopulates_cache(monkeypatch):
    monkeypatch.setattr(
        srl,
        "postUserReviewCached",
        AsyncMock(return_value={"status": "success", "table": "movie_reviews"}),
    )
    review = _media("m100")
    result = await srl.postUserReview(review)
    assert result["status"] == "success"
    assert srl.cache_lock_logic.repolulateCache.await_count == 2


async def test_post_user_review_error(monkeypatch):
    monkeypatch.setattr(
        srl, "postUserReviewCached", AsyncMock(side_effect=RuntimeError("cache err"))
    )
    result = await srl.postUserReview(_media("b1"))
    assert result["status"] == "error"


async def test_clean_supabase_review_and_reviews(monkeypatch):
    monkeypatch.setattr(
        srl.datacleaning, "cleanSupabaseReview", lambda r: {**r, "cleaned": True}
    )
    review = {"uid": "u1", "media_id": "m1", "finished_on": "2024-01-01"}
    cleaned = await srl.cleanSupabaseReview(review)
    assert cleaned["username"] == "alice"
    assert cleaned["cleaned"] is True

    async def maybe_fail(r):
        if r["uid"] == "bad":
            raise RuntimeError("bad review")
        return {**r, "username": "ok"}

    monkeypatch.setattr(srl, "cleanSupabaseReview", maybe_fail)
    result = await srl.cleanSupabaseReviews([{"uid": "good"}, {"uid": "bad"}])
    assert len(result) == 1
    assert result[0]["uid"] == "good"


async def test_match_review_to_media(monkeypatch):
    monkeypatch.setattr(
        srl.external_media_service,
        "getMediaFromExternalAPIs",
        AsyncMock(return_value=[{"id": "m22", "title": "x"}]),
    )
    review = {"media_id": "m22", "finished_on": "2024-01-01"}
    out = await srl.matchReviewToMedia(review)
    assert out[0] == review
    assert out[1]["id"] == "m22"


async def test_get_all_user_reviews_cached_success_and_error(monkeypatch):
    sb = MagicMock()
    mapping = {
        "book_reviews": _query(
            _response(
                data=[{"uid": "u1", "media_id": "b1", "finished_on": "2024-01-01"}]
            )
        ),
        "movie_reviews": _query(
            _response(
                data=[{"uid": "u1", "media_id": "m1", "finished_on": "2024-01-02"}]
            )
        ),
        "television_reviews": _query(
            _response(
                data=[{"uid": "u1", "media_id": "t1", "finished_on": "2024-01-03"}]
            )
        ),
    }
    sb.table.side_effect = lambda name: mapping[name]
    monkeypatch.setattr(srl, "supabase", sb)
    monkeypatch.setattr(
        srl, "cleanSupabaseReviews", AsyncMock(side_effect=lambda reviews: reviews)
    )

    all_result = await srl.getAllUserReviewsCached("u1", "a")
    assert len(all_result["result"]) == 3

    books_only = await srl.getAllUserReviewsCached("u1", "b")
    assert len(books_only["result"]) == 1
    assert books_only["result"][0]["media_id"].startswith("b")

    sb.table.side_effect = RuntimeError("db")
    err = await srl.getAllUserReviewsCached("u1", "a")
    assert err["status"] == "error"


async def test_get_all_user_reviews_uses_cache_layer(monkeypatch):
    monkeypatch.setattr(
        srl.cache_lock_logic,
        "cacheLockLogicLRU",
        AsyncMock(return_value={"result": [1, 2, 3]}),
    )
    out = await srl.getAllUserReviews("u1", "a")
    assert out == [1, 2, 3]


async def test_get_user_reviews_visibility_filters(monkeypatch):
    reviews = [
        {"review_visibility": "Public"},
        {"review_visibility": "Friends Only"},
        {"review_visibility": "My Eyes Only"},
    ]
    monkeypatch.setattr(srl, "getAllUserReviews", AsyncMock(return_value=reviews))

    public = await srl.getUserReviews("u1", "a", "public")
    friend = await srl.getUserReviews("u1", "a", "friend")
    me = await srl.getUserReviews("u1", "a", "me")

    assert len(public) == 1
    assert len(friend) == 2
    assert len(me) == 3


async def test_update_user_review_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(srl, "supabase", sb)
    review = _media("t7")
    success = await srl.updateUserReview(review)
    assert success["status"] == "success"
    assert success["table"] == "television_reviews"
    assert srl.cache_lock_logic.repolulateCache.await_count >= 2

    sb.table.return_value = _query(exc=RuntimeError("fail"))
    err = await srl.updateUserReview(review)
    assert err["status"] == "error"


async def test_get_trending_reviews_success_and_error(monkeypatch):
    sb = MagicMock()

    def rpc_side_effect(name):
        if "books" in name:
            return SimpleNamespace(execute=lambda: _response(data=[{"media_id": "b1"}]))
        if "movies" in name:
            return SimpleNamespace(execute=lambda: _response(data=[{"media_id": "m1"}]))
        return SimpleNamespace(execute=lambda: _response(data=[{"media_id": "t1"}]))

    sb.rpc.side_effect = rpc_side_effect
    monkeypatch.setattr(srl, "supabase", sb)

    out = await srl.getTrendingReviews("a")
    assert out[srl.book_id_identifier][0]["media_id"] == "b1"
    assert out[srl.movie_id_identifier][0]["media_id"] == "m1"
    assert out[srl.tv_id_identifier][0]["media_id"] == "t1"

    sb.rpc.side_effect = RuntimeError("rpc failed")
    err = await srl.getTrendingReviews("a")
    assert err["status"] == "error"


async def test_get_trending_media_cached_and_get_trending(monkeypatch):
    trending_reviews = {
        srl.book_id_identifier: [{srl.id_key: "b1"}],
        srl.movie_id_identifier: [{srl.id_key: "m1"}],
        srl.tv_id_identifier: [{srl.id_key: "t1"}],
    }
    monkeypatch.setattr(
        srl, "getTrendingReviews", AsyncMock(return_value=trending_reviews)
    )

    async def _match(review):
        return review, {"id": review[srl.id_key]}

    monkeypatch.setattr(srl, "matchReviewToMedia", AsyncMock(side_effect=_match))
    medias = await srl.getTrendingMediaCached("a")
    assert medias[srl.book_id_identifier][0]["id"] == "b1"
    assert medias[srl.movie_id_identifier][0]["id"] == "m1"
    assert medias[srl.tv_id_identifier][0]["id"] == "t1"

    monkeypatch.setattr(
        srl, "getTrendingReviews", AsyncMock(return_value={"status": "error"})
    )
    empty = await srl.getTrendingMediaCached("a")
    assert empty[srl.book_id_identifier] == []

    monkeypatch.setattr(
        srl.cache_lock_logic, "cacheLockLogicTTL", AsyncMock(return_value={"ok": True})
    )
    got = await srl.getTrending({"type": "a"})
    assert got == {"ok": True}


@pytest.mark.parametrize(
    "media_id, table",
    [("m1", "movie_reviews"), ("t1", "television_reviews"), ("b1", "book_reviews")],
)
async def test_get_user_media_reviews_table_routing(monkeypatch, media_id, table):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(data=[{"uid": "u1", "media_id": media_id}])
    )
    monkeypatch.setattr(srl, "supabase", sb)
    monkeypatch.setattr(srl, "cleanSupabaseReviews", AsyncMock(return_value=[{"x": 1}]))
    out = await srl.getMediaReviews(media_id)
    assert out == [{"x": 1}]
    sb.table.assert_called_with(table)


def test_check_friendship_true_and_false(monkeypatch):
    sb = MagicMock()
    q_true = _query(_response(data=[{"following_id": "u2"}]))
    q_false = _query(_response(data=[]))

    sb.table.return_value = q_true
    monkeypatch.setattr(srl, "supabase", sb)
    assert srl.checkFriendship("u1", "u2") is True

    sb.table.return_value = q_false
    assert srl.checkFriendship("u1", "u2") is False


async def test_match_user_to_media_reviews_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"uid": "u1", "media_id": "m1"}]))
    monkeypatch.setattr(srl, "supabase", sb)
    monkeypatch.setattr(
        srl,
        "cleanSupabaseReviews",
        AsyncMock(return_value=[{"uid": "u1", "media_id": "m1"}]),
    )
    out = await srl.matchUserToMediaReviews("u1", "m1", "a")
    assert out["media_id"] == "m1"

    monkeypatch.setattr(
        srl, "cleanSupabaseReviews", AsyncMock(side_effect=RuntimeError("bad"))
    )
    err = await srl.matchUserToMediaReviews("u1", "m1", "a")
    assert err["status"] == "error"


async def test_get_user_media_review_visibility_branches(monkeypatch):
    monkeypatch.setattr(
        srl,
        "getUserReviews",
        AsyncMock(return_value=[{"media_id": "m1", "finished_on": "2024-01-02"}]),
    )
    monkeypatch.setattr(
        srl,
        "matchReviewToMedia",
        AsyncMock(return_value=({"finished_on": "2024-01-02"}, {"id": "m1"})),
    )
    monkeypatch.setattr(
        srl, "sortReviewMediaListByDate", AsyncMock(side_effect=lambda x: x)
    )

    out_me = await srl.getUserMediaReview("u1", "u1", "a")
    assert len(out_me) == 1

    monkeypatch.setattr(srl, "checkFriendship", lambda a, b: True)
    out_friend = await srl.getUserMediaReview("uX", "u1", "a")
    assert len(out_friend) == 1

    monkeypatch.setattr(srl, "checkFriendship", lambda a, b: False)
    out_public = await srl.getUserMediaReview("uX", "u1", "a")
    assert len(out_public) == 1


async def test_get_following_media_reviews(monkeypatch):
    monkeypatch.setattr(
        srl.supabase_user_logic,
        "fetchFollowing",
        AsyncMock(return_value=[{"uid": "u2"}, {"uid": "u3"}]),
    )
    monkeypatch.setattr(
        srl,
        "getUserMediaReview",
        AsyncMock(
            side_effect=[
                [({"finished_on": "2024-01-01"}, {"id": "m1"})],
                [({"finished_on": "2024-02-01"}, {"id": "m2"})],
            ]
        ),
    )
    monkeypatch.setattr(
        srl, "sortReviewMediaListByDate", AsyncMock(side_effect=lambda x: x)
    )

    out = await srl.getFollowingMediaReviews("u1", "a")
    assert len(out) == 2


async def test_delete_user_review_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(srl, "supabase", sb)

    out = await srl.deleteUserReview("u1", "m3")
    assert out == {"status": "ok"}
    assert srl.cache_lock_logic.repolulateCache.await_count >= 2

    sb.table.return_value = _query(exc=RuntimeError("delete failed"))
    with pytest.raises(srl.HTTPException):
        await srl.deleteUserReview("u1", "b3")


async def test_season_review_crud(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(data=[{"review_id": 1, "season_number": 1}])
    )
    monkeypatch.setattr(srl, "supabase", sb)

    got = await srl.getSeasonReviews("1")
    assert got[0]["season_number"] == 1

    ok = await srl.updateSeasonReview(
        {
            "review_id": 1,
            "season_number": 2,
            "rating": 5,
            "review_text": "great",
            "finished_on": "2024-01-01",
            "spoiler": False,
            "watched": True,
        }
    )
    assert ok["status"] == "success"

    deleted = await srl.deleteSeasonReview(1, 2)
    assert deleted == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("boom"))
    err = await srl.getSeasonReviews("1")
    assert err["status"] == "error"

    err2 = await srl.updateSeasonReview(
        {
            "review_id": 1,
            "season_number": 2,
            "rating": 5,
            "review_text": "great",
            "finished_on": "2024-01-01",
            "spoiler": False,
            "watched": True,
        }
    )
    assert err2["status"] == "error"

    with pytest.raises(srl.HTTPException):
        await srl.deleteSeasonReview(1, 2)


async def test_get_review_media_from_report_and_get_season_reviews_for_user(
    monkeypatch,
):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(
            data=[
                {"id": 44, "media_id": "m55", "uid": "u1", "finished_on": "2024-01-01"}
            ]
        )
    )
    monkeypatch.setattr(srl, "supabase", sb)
    monkeypatch.setattr(
        srl,
        "cleanSupabaseReview",
        AsyncMock(return_value={"id": 44, "username": "alice"}),
    )
    monkeypatch.setattr(
        srl,
        "matchReviewToMedia",
        AsyncMock(return_value=({"id": 44}, {"id": "m55", "title": "M"})),
    )

    out = await srl.getReviewMediaFromReport("m55,44")
    assert out[0] == "m"
    assert out[1]["username"] == "alice"
    assert out[2]["id"] == "m55"

    sb.table.return_value = _query(
        _response(data=[{"review_id": 44, "season_number": 1}])
    )
    seasons = await srl.getSeasonReviewsForUser("u1", 44)
    assert seasons[0]["season_number"] == 1

    sb.table.return_value = _query(exc=RuntimeError("bad read"))
    err = await srl.getReviewMediaFromReport("m55,44")
    assert err["status"] == "error"
    err2 = await srl.getSeasonReviewsForUser("u1", 44)
    assert err2["status"] == "error"
