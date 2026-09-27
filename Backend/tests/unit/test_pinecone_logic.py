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


class DummyPinecone:
    def __init__(self, _api_key):
        self.inference = types.SimpleNamespace(embed=lambda **_kwargs: {"data": []})

    def Index(self, _name):
        return types.SimpleNamespace(
            query=lambda **_kwargs: {"matches": []},
            fetch=lambda **_kwargs: {"vectors": {}},
            upsert=lambda **_kwargs: None,
        )


fastapi_mod = types.ModuleType("fastapi")
fastapi_mod.FastAPI = DummyFastAPI

pinecone_mod = types.ModuleType("pinecone")
pinecone_mod.Pinecone = DummyPinecone

dotenv_mod = types.ModuleType("dotenv")
dotenv_mod.load_dotenv = lambda: None

cache_lock_logic_mod = types.ModuleType("cache_lock_logic")


class DummyCache(dict):
    def __init__(self, *args, **kwargs):
        super().__init__()


def _cached(_cache):
    def _decorator(fn):
        return fn

    return _decorator


cachetools_mod = types.ModuleType("cachetools")
cachetools_mod.TTLCache = DummyCache
cachetools_mod.LRUCache = DummyCache
cachetools_mod.cached = _cached

_original_fastapi = sys.modules.get("fastapi")
_original_pinecone = sys.modules.get("pinecone")
_original_dotenv = sys.modules.get("dotenv")
_original_cache_lock_logic = sys.modules.get("cache_lock_logic")
_original_cachetools = sys.modules.get("cachetools")

sys.modules["fastapi"] = fastapi_mod
sys.modules["pinecone"] = pinecone_mod
sys.modules["dotenv"] = dotenv_mod
sys.modules["cache_lock_logic"] = cache_lock_logic_mod
sys.modules["cachetools"] = cachetools_mod


import pinecone_logic as pl


def _restore_module(name, original):
    if original is None:
        sys.modules.pop(name, None)
    else:
        sys.modules[name] = original


_restore_module("fastapi", _original_fastapi)
_restore_module("pinecone", _original_pinecone)
_restore_module("dotenv", _original_dotenv)
_restore_module("cache_lock_logic", _original_cache_lock_logic)
_restore_module("cachetools", _original_cachetools)


class DummyMatch:
    def __init__(self, payload):
        self.payload = payload

    def to_dict(self):
        return self.payload


def _sample_media(media_id="m1"):
    return {
        pl.id_key: media_id,
        pl.title_key: "Title",
        pl.description_key: "Description",
        pl.genres_key: ["Drama", "Thriller"],
        pl.creator_key: "Creator",
        pl.media_length_key: 100,
        pl.season_count_key: 1,
    }


async def test_get_info_for_vectorization_builds_text_and_metadata():
    media = _sample_media("b77")

    text, metadata = await pl.getInfoForVectorization(media)

    assert text == "Title -  Description - Drama, Thriller"
    assert metadata is media


def test_log_time_check_prints_only_when_enabled(monkeypatch):
    mock_print = MagicMock()
    monkeypatch.setattr("builtins.print", mock_print)

    pl.logTimeCheck("MSG", False)
    assert mock_print.call_count == 0

    pl.logTimeCheck("MSG", True)
    assert mock_print.call_count == 1
    assert "MSG" in mock_print.call_args[0][0]


async def test_embed_text_reads_values_from_dict_response(monkeypatch):
    embed_mock = MagicMock(return_value={"data": [{"values": [0.1, 0.2]}]})
    monkeypatch.setattr(pl.pinecone_connection.inference, "embed", embed_mock)

    vector = await pl.embedText("hello", "query")

    assert vector == [0.1, 0.2]
    assert embed_mock.call_args.kwargs["parameters"]["input_type"] == "query"


async def test_embed_text_reads_values_from_object_response(monkeypatch):
    class EmbeddingObj:
        def __init__(self):
            self.values = [0.3, 0.4]

    class ResponseObj:
        def __init__(self):
            self.data = [EmbeddingObj()]

    monkeypatch.setattr(
        pl.pinecone_connection.inference, "embed", MagicMock(return_value=ResponseObj())
    )

    vector = await pl.embedText("hello", "passage")

    assert vector == [0.3, 0.4]


async def test_embed_text_returns_empty_for_empty_response(monkeypatch):
    monkeypatch.setattr(
        pl.pinecone_connection.inference, "embed", MagicMock(return_value={"data": []})
    )

    vector = await pl.embedText("hello", "query")

    assert vector == []


async def test_query_and_passage_vector_from_text(monkeypatch):
    embed_mock = AsyncMock(side_effect=[[1.0], [2.0], []])
    monkeypatch.setattr(pl, "embedText", embed_mock)

    query_vector = await pl.getQueryVectorFromText("abc")
    passage_vector = await pl.getPassageVectorFromText("m9", "xyz")
    empty_passage = await pl.getPassageVectorFromText("m9", "xyz")

    assert query_vector == [1.0]
    assert passage_vector == [2.0]
    assert empty_passage == []
    assert embed_mock.await_args_list[0].args == ("abc",)
    assert embed_mock.await_args_list[0].kwargs == {"embed_type": "query"}
    assert embed_mock.await_args_list[1].kwargs == {"embed_type": "passage"}


async def test_get_similar_media_using_text_handles_empty_and_success(monkeypatch):
    monkeypatch.setattr(
        pl, "getQueryVectorFromText", AsyncMock(side_effect=[[], [0.5, 0.7]])
    )
    query_mock = MagicMock(
        return_value={"matches": [DummyMatch({"id": "m1", "score": 0.9})]}
    )
    monkeypatch.setattr(pl.PINECONE_INDEX, "query", query_mock)

    empty_result = await pl.getSimilarMediaUsingText("hello", pl.movie_id_identifier, 5)
    filled_result = await pl.getSimilarMediaUsingText(
        "hello", pl.movie_id_identifier, 5
    )

    assert empty_result == []
    assert filled_result == [{"id": "m1", "score": 0.9}]
    assert query_mock.call_args.kwargs["namespace"] == pl.movie_id_identifier


async def test_get_similar_media_using_vector_handles_empty_and_success(monkeypatch):
    query_mock = MagicMock(return_value={"matches": [DummyMatch({"id": "b2"})]})
    monkeypatch.setattr(pl.PINECONE_INDEX, "query", query_mock)

    empty_result = await pl.getSimilarMediaUsingVector([], pl.book_id_identifier, 3)
    filled_result = await pl.getSimilarMediaUsingVector(
        [1.0, 2.0], pl.book_id_identifier, 3
    )

    assert empty_result == []
    assert filled_result == [{"id": "b2"}]


async def test_get_similar_media_using_media(monkeypatch):
    monkeypatch.setattr(
        pl,
        "getInfoForVectorization",
        AsyncMock(return_value=("some text", {"meta": 1})),
    )
    monkeypatch.setattr(
        pl, "getQueryVectorFromText", AsyncMock(side_effect=[[], [0.9]])
    )
    query_mock = MagicMock(return_value={"matches": [DummyMatch({"id": "t9"})]})
    monkeypatch.setattr(pl.PINECONE_INDEX, "query", query_mock)

    media = _sample_media("t9")
    empty_result = await pl.getSimilarMediaUsingMedia(media, pl.tv_id_identifier, 2)
    filled_result = await pl.getSimilarMediaUsingMedia(media, pl.tv_id_identifier, 2)

    assert empty_result == []
    assert filled_result == [{"id": "t9"}]


async def test_store_media_success(monkeypatch):
    index = types.SimpleNamespace(upsert=MagicMock())
    media = _sample_media("m22")

    monkeypatch.setattr(
        pl, "getInfoForVectorization", AsyncMock(return_value=("text", media))
    )
    monkeypatch.setattr(pl, "embedText", AsyncMock(return_value=[0.1, 0.2]))

    result = await pl.storeMedia(index, media)

    assert result == {"status": "success", "message": "success"}
    assert index.upsert.call_args.kwargs["namespace"] == "m"


async def test_store_media_exception_branch(monkeypatch):
    media = _sample_media("m23")

    def _raise_upsert(**_kwargs):
        raise RuntimeError("upsert failed")

    index = types.SimpleNamespace(upsert=_raise_upsert)
    monkeypatch.setattr(
        pl, "getInfoForVectorization", AsyncMock(return_value=("text", media))
    )
    monkeypatch.setattr(pl, "embedText", AsyncMock(return_value=[0.1, 0.2]))

    result = await pl.storeMedia(index, media)

    assert result is None


async def test_get_media_using_id_single_found_and_missing():
    found_index = types.SimpleNamespace(
        fetch=MagicMock(return_value={"vectors": {"m1": {"values": [1, 2]}}})
    )
    missing_index = types.SimpleNamespace(fetch=MagicMock(return_value={"vectors": {}}))

    found = await pl.getMediaUsingIDSingle(found_index, "m1")
    missing = await pl.getMediaUsingIDSingle(missing_index, "m1")

    assert found == [{"values": [1, 2]}]
    assert missing == []


async def test_get_media_using_id_orchestrates_fetch_and_store(monkeypatch):
    media = _sample_media("m90")

    # Existing media path: no store call, second fetch result returned.
    get_single_existing = AsyncMock(side_effect=[[{"values": [1]}], [{"values": [2]}]])
    store_mock = AsyncMock()
    monkeypatch.setattr(pl, "getMediaUsingIDSingle", get_single_existing)
    monkeypatch.setattr(pl, "storeMedia", store_mock)

    existing_result = await pl.getMediaUsingID(media)
    assert existing_result == [{"values": [2]}]
    assert store_mock.await_count == 0

    # Missing media path: store called once before second fetch.
    get_single_missing = AsyncMock(side_effect=[[], [{"values": [3]}]])
    monkeypatch.setattr(pl, "getMediaUsingIDSingle", get_single_missing)
    monkeypatch.setattr(pl, "storeMedia", store_mock)

    missing_result = await pl.getMediaUsingID(media)
    assert missing_result == [{"values": [3]}]
    assert store_mock.await_count == 1
