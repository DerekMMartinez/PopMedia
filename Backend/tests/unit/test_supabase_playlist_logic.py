import os
import sys
import types
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


fastapi_mod = types.ModuleType("fastapi")
fastapi_mod.FastAPI = MagicMock
fastapi_mod.Depends = MagicMock()
fastapi_mod.HTTPException = Exception
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
sys.modules.setdefault(
    "cache_lock_logic",
    SimpleNamespace(
        cacheLockLogicLRU=AsyncMock(),
        cacheLockLogicTTL=AsyncMock(),
        repolulateCache=AsyncMock(),
    ),
)
sys.modules.setdefault(
    "supabase_connection_logic", SimpleNamespace(supabase=MagicMock())
)
sys.modules.setdefault(
    "external_media_service", SimpleNamespace(getMediaFromExternalAPIs=AsyncMock())
)


import supabase_playlist_logic as spl


def _response(data=None):
    return SimpleNamespace(data=([] if data is None else data))


def _query(response=None, exc=None):
    q = MagicMock()
    for method in ["select", "insert", "update", "delete", "eq", "ilike", "limit"]:
        getattr(q, method).return_value = q
    if exc is not None:
        q.execute.side_effect = exc
    else:
        q.execute.return_value = response if response is not None else _response([])
    return q


@pytest.fixture(autouse=True)
def isolate_media_service(monkeypatch):
    monkeypatch.setattr(
        spl.external_media_service,
        "getMediaFromExternalAPIs",
        AsyncMock(
            side_effect=lambda request: [
                {"id": request["media_id"], "type": request["type"]}
            ]
        ),
    )


def test_time_calculators():
    assert spl.hourCalculator(1.5) == 5400
    assert spl.minuteCalculator(2.0) == 120


async def test_get_playlists_success_and_error(monkeypatch):
    owned = _response(data=[{"pid": 1, "uid": "u1"}])
    collab = _response(data=[{"playlist_attributes": {"pid": 2, "uid": "u2"}}])
    sb = MagicMock()
    sb.table.side_effect = [_query(owned), _query(collab)]
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.getPlaylists("u1") == [
        {"pid": 1, "uid": "u1"},
        {"pid": 2, "uid": "u2"},
    ]

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("db down"))
    monkeypatch.setattr(spl, "supabase", sb_err)
    result = await spl.getPlaylists("u1")
    assert result["status"] == "error"


async def test_delete_playlist_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.deletePlaylist(5) == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("cannot delete"))
    assert (await spl.deletePlaylist(5))["status"] == "error"


async def test_get_collaborators_with_and_without_owner_and_error(monkeypatch):
    collab = _response(data=[{"users": {"uid": "u2"}}, {"users": {"uid": "u3"}}])
    owner = _response(data=[{"uid": "owner"}])

    sb = MagicMock()
    sb.table.side_effect = [_query(collab), _query(owner)]
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.getCollaborators(1, True, "owner") == [
        {"uid": "owner"},
        {"uid": "u2"},
        {"uid": "u3"},
    ]

    sb2 = MagicMock()
    sb2.table.return_value = _query(collab)
    monkeypatch.setattr(spl, "supabase", sb2)
    assert await spl.getCollaborators(1, False, "owner") == [
        {"uid": "u2"},
        {"uid": "u3"},
    ]

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("boom"))
    monkeypatch.setattr(spl, "supabase", sb_err)
    assert (await spl.getCollaborators(1, False, "owner"))["status"] == "error"


async def test_get_playlist_media_all_type(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(data=[{"media_id": "m1"}, {"media_id": "t2"}, {"media_id": "b3"}])
    )
    monkeypatch.setattr(spl, "supabase", sb)
    result = await spl.getPlaylistMedia(9, "a")
    assert [m["id"] for m in result] == ["m1", "t2", "b3"]


async def test_get_playlist_media_movies_filters(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(data=[{"media_id": "m1"}, {"media_id": "t2"}, {"media_id": "m3"}])
    )
    monkeypatch.setattr(spl, "supabase", sb)
    result = await spl.getPlaylistMedia(9, "m")
    assert [m["id"] for m in result] == ["m1", "m3"]


async def test_get_playlist_media_tv_filters(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(data=[{"media_id": "t1"}, {"media_id": "b2"}, {"media_id": "t3"}])
    )
    monkeypatch.setattr(spl, "supabase", sb)
    result = await spl.getPlaylistMedia(9, "t")
    assert [m["id"] for m in result] == ["t1", "t3"]


async def test_get_playlist_media_books_default_branch_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(
        _response(data=[{"media_id": "b1"}, {"media_id": "m2"}, {"media_id": "b3"}])
    )
    monkeypatch.setattr(spl, "supabase", sb)
    result = await spl.getPlaylistMedia(9, "b")
    assert [m["id"] for m in result] == ["b1", "b3"]

    sb_err = MagicMock()
    sb_err.table.return_value = _query(exc=RuntimeError("lookup fail"))
    monkeypatch.setattr(spl, "supabase", sb_err)
    assert (await spl.getPlaylistMedia(9, "a"))["status"] == "error"


async def test_add_media_to_playlist_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.addMediaToPlaylist(2, "m1") == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("insert fail"))
    assert (await spl.addMediaToPlaylist(2, "m1"))["status"] == "error"


async def test_add_collaborator_to_playlist_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.addCollaboratorToPlaylist(2, "u1") == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("insert fail"))
    assert (await spl.addCollaboratorToPlaylist(2, "u1"))["status"] == "error"


async def test_delete_media_from_playlist_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.deleteMediaFromPlaylist(2, "m1") == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("delete fail"))
    assert (await spl.deleteMediaFromPlaylist(2, "m1"))["status"] == "error"


async def test_delete_collaborator_from_playlist_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"ok": True}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.deleteCollaboratorFromPlaylist(2, "u1") == {"status": "ok"}

    sb.table.return_value = _query(exc=RuntimeError("delete fail"))
    assert (await spl.deleteCollaboratorFromPlaylist(2, "u1"))["status"] == "error"


async def test_post_playlist_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"pid": 42}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.postPlaylist("u1", "n", "d", "img", True) == 42

    sb.table.return_value = _query(exc=RuntimeError("insert fail"))
    assert (await spl.postPlaylist("u1", "n", "d", "img", True))["status"] == "error"


async def test_update_playlist_success_and_error(monkeypatch):
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"pid": 42}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.updatePlaylist(42, "u1", "n", "d", "img", False) == 42

    sb.table.return_value = _query(exc=RuntimeError("update fail"))
    assert (await spl.updatePlaylist(42, "u1", "n", "d", "img", False))[
        "status"
    ] == "error"


async def test_get_playlists_using_search_invalid_and_valid(monkeypatch):
    monkeypatch.setattr(spl.datacleaning, "validateUserInput", lambda _: "")
    assert await spl.getPlaylistsUsingSearch({"input": "   "}) == []

    monkeypatch.setattr(spl.datacleaning, "validateUserInput", lambda _: "road")
    sb = MagicMock()
    sb.table.return_value = _query(_response(data=[{"pid": 1, "name": "Road Trip"}]))
    monkeypatch.setattr(spl, "supabase", sb)
    assert await spl.getPlaylistsUsingSearch({"input": "road"}) == [
        {"pid": 1, "name": "Road Trip"}
    ]
