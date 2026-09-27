import os
import sys
import types
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
sys.modules["firebase_admin"] = firebase_mod

supabase_mod = types.ModuleType("supabase")
supabase_mod.create_client = MagicMock()
supabase_mod.Client = MagicMock()
sys.modules["supabase"] = supabase_mod

sys.modules.setdefault("dotenv", SimpleNamespace(load_dotenv=MagicMock()))
sys.modules.setdefault("requests", MagicMock())
sys.modules.setdefault("markdown", MagicMock())
sys.modules.setdefault("bs4", SimpleNamespace(BeautifulSoup=MagicMock()))


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
sys.modules["cache_lock_logic"] = SimpleNamespace(
    cacheLockLogicLRU=AsyncMock(),
    repolulateCache=AsyncMock(),
)
sys.modules["supabase_connection_logic"] = SimpleNamespace(supabase=MagicMock())

sys.modules.pop("supabase_user_logic", None)

import supabase_user_logic as sul

sul.HTTPException = DummyHTTPException


def _response(data=None, count=None):
    return SimpleNamespace(data=([] if data is None else data), count=count)


def _query(response=None, exc=None):
    q = MagicMock()
    for method in [
        "select",
        "insert",
        "update",
        "delete",
        "upsert",
        "eq",
        "in_",
        "or_",
        "limit",
    ]:
        getattr(q, method).return_value = q
    if exc is not None:
        q.execute.side_effect = exc
    else:
        q.execute.return_value = response if response is not None else _response([])
    return q


@pytest.fixture(autouse=True)
def isolate_cache_boundary(monkeypatch):
    async def _cache_passthrough(args, CACHE=None, LOCK=None, function=None):
        return await function(*args)

    monkeypatch.setattr(
        sul.cache_lock_logic,
        "cacheLockLogicLRU",
        AsyncMock(side_effect=_cache_passthrough),
    )
    monkeypatch.setattr(
        sul.cache_lock_logic, "repolulateCache", AsyncMock(return_value=None)
    )


def test_time_converters():
    assert sul.hourCalculator(2) == 7200
    assert sul.minuteCalculator(2.5) == 150


async def test_create_new_follow_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)

    result = await sul.createNewFollow("u1", "u2")
    assert result == {"status": "ok"}
    assert sul.cache_lock_logic.repolulateCache.await_count == 2

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("boom"))
    monkeypatch.setattr(sul, "supabase", sb_err)
    with pytest.raises(DummyHTTPException) as exc_info:
        await sul.createNewFollow("u1", "u2")
    assert exc_info.value.status_code == 401


async def test_delete_follow_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert await sul.deleteFollow("u1", "u2") == {"status": "ok"}

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("delete failed"))
    monkeypatch.setattr(sul, "supabase", sb_err)
    with pytest.raises(DummyHTTPException) as exc_info:
        await sul.deleteFollow("u1", "u2")
    assert exc_info.value.status_code == 500


def test_check_follow_true_false_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"following_id": "u2"}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.checkFollow("u1", "u2") == {"status": "ok", "is_following": True}

    sb.table.return_value = _query(_response(data=[]))
    assert sul.checkFollow("u1", "u2") == {"status": "ok", "is_following": False}

    sb.table.return_value = _query(exc=RuntimeError("x"))
    with pytest.raises(DummyHTTPException) as exc_info:
        sul.checkFollow("u1", "u2")
    assert exc_info.value.status_code == 401


async def test_fetch_following_cached_paths(monkeypatch):
    q_following = _query(
        _response(data=[{"following_id": "u2"}, {"following_id": "u3"}])
    )
    q_users = _query(_response(data=[{"uid": "u2"}, {"uid": "u3"}]))
    sb = MagicMock()
    sb.table.side_effect = [q_following, q_users]
    monkeypatch.setattr(sul, "supabase", sb)
    assert await sul.fetchFollowingCached("u1") == [{"uid": "u2"}, {"uid": "u3"}]

    q_empty = _query(_response(data=[]))
    sb.table.side_effect = [q_empty]
    assert await sul.fetchFollowingCached("u1") == []

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("db"))
    monkeypatch.setattr(sul, "supabase", sb_err)
    with pytest.raises(RuntimeError):
        await sul.fetchFollowingCached("u1")


async def test_fetch_following_wrapper(monkeypatch):
    monkeypatch.setattr(
        sul, "fetchFollowingCached", AsyncMock(return_value=[{"uid": "u2"}])
    )
    assert await sul.fetchFollowing("u1") == [{"uid": "u2"}]


async def test_fetch_followers_cached_paths(monkeypatch):
    q_followers = _query(_response(data=[{"user_id": "u9"}]))
    q_users = _query(_response(data=[{"uid": "u9"}]))
    sb = MagicMock()
    sb.table.side_effect = [q_followers, q_users]
    monkeypatch.setattr(sul, "supabase", sb)
    assert await sul.fetchFollowersCached("u1") == [{"uid": "u9"}]

    sb.table.side_effect = [_query(_response(data=[]))]
    assert await sul.fetchFollowersCached("u1") == []

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("db"))
    monkeypatch.setattr(sul, "supabase", sb_err)
    with pytest.raises(RuntimeError):
        await sul.fetchFollowersCached("u1")


async def test_fetch_followers_wrapper(monkeypatch):
    monkeypatch.setattr(
        sul, "fetchFollowersCached", AsyncMock(return_value=[{"uid": "u7"}])
    )
    assert await sul.fetchFollowers("u1") == [{"uid": "u7"}]


async def test_get_username_cached_exists_missing_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"username": "alice"}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert await sul.getUsernameCached("u1") == {
        "status": "success",
        "exists": True,
        "username": "alice",
    }

    sb.table.return_value = _query(_response(data=[]))
    assert await sul.getUsernameCached("u1") == {
        "status": "success",
        "exists": False,
        "username": "does not exist",
    }

    sb.table.return_value = _query(exc=RuntimeError("nope"))
    result = await sul.getUsernameCached("u1")
    assert result["status"] == "error"
    assert "nope" in result["message"]


async def test_get_username_wrapper(monkeypatch):
    monkeypatch.setattr(
        sul, "getUsernameCached", AsyncMock(return_value={"username": "a"})
    )
    assert await sul.getUsername("u1") == {"username": "a"}


def test_get_user(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"uid": "u1"}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.getUser("u1") == [{"uid": "u1"}]


def test_get_user_using_username_paths(monkeypatch):
    monkeypatch.setattr(sul.datacleaning, "validateUserInput", lambda value: "")
    assert sul.getUserUsingUsername("   ") == []

    monkeypatch.setattr(sul.datacleaning, "validateUserInput", lambda value: "alice")
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"uid": "u1", "username": "alice"}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.getUserUsingUsername("alice") == [{"uid": "u1", "username": "alice"}]


async def test_get_users_using_search_delegates(monkeypatch):
    mock = MagicMock(return_value=[{"uid": "u3"}])
    monkeypatch.setattr(sul, "getUserUsingUsername", mock)
    result = await sul.getUsersUsingSearch({"input": "bob"})
    assert result == [{"uid": "u3"}]
    mock.assert_called_once_with("bob")


def test_check_username_taken_branches(monkeypatch):
    sb = MagicMock()
    sb.table.side_effect = [
        _query(_response(data=[])),
        _query(_response(data=[{"email": "a@b.com"}])),
    ]
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.checkUsernameTaken("alice", "a@b.com") == {"exists": "false"}

    sb.table.side_effect = [
        _query(_response(data=[{"username": "alice"}])),
        _query(_response(data=[])),
    ]
    assert sul.checkUsernameTaken("alice", "a@b.com") == {"exists": "true"}

    sb.table.side_effect = [
        _query(_response(data=[])),
        _query(_response(data=[])),
    ]
    assert sul.checkUsernameTaken("newuser", "x@y.com") == {"exists": "false"}


async def test_post_new_user_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)
    user = {
        "uid": "u1",
        "username": "alice",
        "email": "a@b.com",
        "name": "Alice",
        "bio": "bio",
        "profile_pic_url": "https://img",
    }
    assert await sul.postNewUser(user) == {"status": "success", "table": "users"}
    assert sul.cache_lock_logic.repolulateCache.await_count >= 1

    sb.table.return_value = _query(exc=RuntimeError("insert fail"))
    result = await sul.postNewUser(user)
    assert result["status"] == "error"


def test_get_check_user_exists_false_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"uid": "u1"}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.getCheckUser("u1") == {"status": "success", "exists": True, "uid": "u1"}

    sb.table.return_value = _query(_response(data=[]))
    assert sul.getCheckUser("u1") == {"status": "success", "exists": False, "uid": "u1"}

    sb.table.return_value = _query(exc=RuntimeError("fail"))
    result = sul.getCheckUser("u1")
    assert result["status"] == "error"


async def test_get_friends(monkeypatch):
    monkeypatch.setattr(
        sul, "fetchFollowing", AsyncMock(return_value=[{"uid": "u2"}, {"uid": "u3"}])
    )
    monkeypatch.setattr(
        sul, "fetchFollowers", AsyncMock(return_value=[{"uid": "u3"}, {"uid": "u4"}])
    )
    assert await sul.getFriends("u1") == [{"uid": "u3"}]


def test_get_admin_true_false_none(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"admin": True}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.getAdmin("u1") is True

    sb.table.return_value = _query(_response(data=[{"admin": False}]))
    assert sul.getAdmin("u1") is False

    sb.table.return_value = _query(_response(data=[]))
    assert sul.getAdmin("u1") is None


def test_set_user_profile_picture_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)

    assert sul.setUserProfilePicture("u1", "profiles/a.jpg") == {"status": "ok"}
    first_update_payload = sb.table.return_value.update.call_args[0][0]
    assert first_update_payload["profile_pic_url"].startswith(
        "https://d21jyc5i6ygo3u.cloudfront.net/"
    )

    assert sul.setUserProfilePicture("u1", "profiles/a.jpg", cloudfront_domain="") == {
        "status": "ok"
    }
    second_update_payload = sb.table.return_value.update.call_args[0][0]
    assert second_update_payload["profile_pic_url"] == "profiles/a.jpg"

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("update fail"))
    monkeypatch.setattr(sul, "supabase", sb_err)
    with pytest.raises(DummyHTTPException) as exc_info:
        sul.setUserProfilePicture("u1", "profiles/a.jpg")
    assert exc_info.value.status_code == 500


def test_get_user_profile_picture_url_paths(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"profile_pic_url": "https://img"}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.getUserProfilePictureUrl("u1") == {"profile_pic_url": "https://img"}

    sb.table.return_value = _query(_response(data=[]))
    assert sul.getUserProfilePictureUrl("u1") == {"profile_pic_url": None}

    sb.table.return_value = _query(exc=RuntimeError("bad"))
    with pytest.raises(DummyHTTPException):
        sul.getUserProfilePictureUrl("u1")


async def test_delete_user_photo_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert await sul.deleteUserPhoto("u1") == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("fail"))
    with pytest.raises(DummyHTTPException):
        await sul.deleteUserPhoto("u1")


def test_delete_account_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.deleteAccount("u1") == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("fail"))
    with pytest.raises(DummyHTTPException):
        sul.deleteAccount("u1")


def test_post_report_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)
    result = sul.postReport("id1", "user", "spam", "u1", "2026-04-08", False)
    assert result == {"status": "success", "table": "reports"}

    sb.table.return_value = _query(exc=RuntimeError("insert fail"))
    result = sul.postReport("id1", "user", "spam", "u1", "2026-04-08", False)
    assert result["status"] == "error"


def test_resolve_report_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.resolveReport(3, True) == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("update fail"))
    with pytest.raises(DummyHTTPException):
        sul.resolveReport(3, True)


def test_get_report_success_empty_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"issue_id": 1}]))
    monkeypatch.setattr(sul, "supabase", sb)
    assert sul.getReport(False) == [{"issue_id": 1}]

    sb.table.return_value = _query(_response(data=[]))
    assert sul.getReport(True) == []

    sb.table.return_value = _query(exc=RuntimeError("select fail"))
    result = sul.getReport(False)
    assert result["status"] == "error"
