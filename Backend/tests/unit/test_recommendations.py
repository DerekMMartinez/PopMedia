import os
import sys
import types
from unittest.mock import AsyncMock

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


_STUBBED_MODULES = [
    "fastapi",
    "standardmedia",
    "mergelists",
    "httpx_logic",
    "pinecone_logic",
    "external_media_service",
]
_ORIGINAL_MODULES = {name: sys.modules.get(name) for name in _STUBBED_MODULES}


def _install_recommendations_stubs():
    fastapi_mod = types.ModuleType("fastapi")

    class DummyFastAPI:
        def post(self, _path):
            def _decorator(fn):
                return fn

            return _decorator

    fastapi_mod.FastAPI = DummyFastAPI
    sys.modules["fastapi"] = fastapi_mod

    standardmedia_mod = types.ModuleType("standardmedia")
    standardmedia_mod.getStandardMediaKeys = lambda: (
        "title",
        "description",
        "overall_rating",
        "media_id",
        "image",
        "api_review_count",
        "genres",
        "release_date",
        "creator",
        "media_length",
        "season_count",
    )
    standardmedia_mod.getStandardReviewKeys = lambda: (
        "uid",
        "username",
        "media_id",
        "rating",
        "review_text",
        "review_visibility",
        "finished_on",
        "spoiler",
    )
    standardmedia_mod.getStandardMediaIdentifiers = lambda: ("b", "m", "t")
    standardmedia_mod.getInvalidMediaValues = lambda: ("N/A", -1)
    sys.modules["standardmedia"] = standardmedia_mod

    mergelists_mod = types.ModuleType("mergelists")

    def mergeThreeLists(a, b, c):
        return list(a) + list(b) + list(c)

    async def mergeKLists(lists):
        out = []
        for item in lists:
            out.extend(item)
        return out

    mergelists_mod.mergeThreeLists = mergeThreeLists
    mergelists_mod.mergeKLists = mergeKLists
    sys.modules["mergelists"] = mergelists_mod

    httpx_mod = types.ModuleType("httpx_logic")
    httpx_mod.httpx_rec_client = object()
    httpx_mod.sendAsyncHttpRequestPost = AsyncMock()
    httpx_mod.sendAsyncHttpRequestGet = AsyncMock()
    sys.modules["httpx_logic"] = httpx_mod

    pinecone_mod = types.ModuleType("pinecone_logic")
    pinecone_mod.getMediaFromPinecone = AsyncMock()
    pinecone_mod.getMediaUsingID = AsyncMock()
    pinecone_mod.getSimilarMediaUsingVector = AsyncMock()
    pinecone_mod.getSimilarMediaUsingText = AsyncMock()
    pinecone_mod.getSimilarMediaUsingMedia = AsyncMock()
    sys.modules["pinecone_logic"] = pinecone_mod

    external_mod = types.ModuleType("external_media_service")
    sys.modules["external_media_service"] = external_mod


_install_recommendations_stubs()
sys.modules.pop("recommendations", None)
import recommendations as rec

for _name, _module in _ORIGINAL_MODULES.items():
    if _module is not None:
        sys.modules[_name] = _module
    else:
        sys.modules.pop(_name, None)


@pytest.fixture(autouse=True)
def reset_globals(monkeypatch):
    monkeypatch.setattr(rec, "VEC_SIZE", 4)
    monkeypatch.setattr(rec, "media_season_count", rec.season_count_key, raising=False)


def _media(mid, genres=None, rating=4.0):
    return {
        rec.id_key: mid,
        rec.genres_key: genres or ["drama"],
        rec.overall_rating_key: rating,
        rec.title_key: f"Title {mid}",
    }


def test_log_time_check_no_crash(capsys):
    rec.logTimeCheck("hello", True)
    assert "hello" in capsys.readouterr().out
    rec.logTimeCheck("quiet", False)
    assert "quiet" not in capsys.readouterr().out


async def test_get_user_average_info_mixed_reviews(monkeypatch):
    user_review_media = {
        "b": [
            (
                {rec.review_rating_key: 4},
                {rec.id_key: "b1", rec.genres_key: ["fantasy"]},
            ),
        ],
        "m": [
            (
                {rec.review_rating_key: 2},
                {rec.id_key: "m1", rec.genres_key: ["horror"]},
            ),
        ],
    }
    monkeypatch.setattr(
        rec, "sendAsyncHttpRequestGet", AsyncMock(return_value=user_review_media)
    )

    async def _vec(media):
        if media[rec.id_key] == "b1":
            return [{"values": [2, 2, 2, 2]}]
        return [{"values": [1, 1, 1, 1]}]

    monkeypatch.setattr(
        rec.pinecone_logic, "getMediaUsingID", AsyncMock(side_effect=_vec)
    )

    out = await rec.getUserAverageInfo({"uid": "u1", "amount": 5, "type": "a"})
    assert out["user_average_liked"] == [3.0, 3.0, 3.0, 3.0]
    assert out["user_average_disliked"] == [1.0, 1.0, 1.0, 1.0]
    assert out["genres_liked"] == {"fantasy"}
    assert out["media_reviewed_list"] == {"b1", "m1"}


async def test_get_user_average_info_empty(monkeypatch):
    monkeypatch.setattr(
        rec, "sendAsyncHttpRequestGet", AsyncMock(return_value={"a": []})
    )
    monkeypatch.setattr(rec.pinecone_logic, "getMediaUsingID", AsyncMock())

    out = await rec.getUserAverageInfo({"uid": "u1", "amount": 5, "type": "a"})
    assert out["user_average_liked"] == [0.0, 0.0, 0.0, 0.0]
    assert out["user_average_disliked"] == [0.0, 0.0, 0.0, 0.0]
    assert out["genres_liked"] == set()
    assert out["media_reviewed_list"] == set()


async def test_collect_similar_helpers(monkeypatch):
    mock_vec = AsyncMock(return_value=[{"id": "m2", "score": 0.9}])
    mock_txt = AsyncMock(return_value=[{"id": "m3", "score": 0.8}])
    monkeypatch.setattr(rec.pinecone_logic, "getSimilarMediaUsingVector", mock_vec)
    monkeypatch.setattr(rec.pinecone_logic, "getSimilarMediaUsingText", mock_txt)

    out_vec = await rec.collectSimilarMediaVector(
        {"user_average_liked": [1], "type": "m", "amount": 3}
    )
    out_txt = await rec.collectSimilarMediaText(
        {"text": "sad", "type": "m", "amount": 3}
    )

    assert out_vec == [{"id": "m2", "score": 0.9}]
    assert out_txt == [{"id": "m3", "score": 0.8}]


async def test_get_media_using_id(monkeypatch):
    post = AsyncMock(return_value=[{rec.id_key: "m9", rec.title_key: "X"}])
    monkeypatch.setattr(rec, "sendAsyncHttpRequestPost", post)

    out = await rec.getMediaUsingID("m9")
    assert out[rec.id_key] == "m9"
    _, kwargs = post.await_args
    assert kwargs["json"][rec.id_key] == "m9"


async def test_get_media_from_pinecone_info_metadata_nested_len_9(monkeypatch):
    item = {
        "metadata": {
            "metadata": [
                "t",
                "d",
                "m1",
                "4.5",
                "img",
                "",
                "a,b",
                "2020",
                "c",
            ]
        }
    }
    out = await rec.getMediaFromPineconeInfo(item)
    assert out == item["metadata"]


async def test_get_media_from_pinecone_info_metadata_dict_and_plain_dict():
    item_new = {
        "metadata": {
            rec.title_key: "n",
            rec.description_key: "d",
            rec.id_key: "b1",
            rec.overall_rating_key: "bad",
            rec.image_key: "img",
            rec.api_review_count_key: "7",
            rec.genres_key: "x,y",
            rec.release_date_key: "2020",
            rec.creator_key: "c",
            rec.media_length_key: 10,
            rec.season_count_key: 1,
        }
    }
    out_new = await rec.getMediaFromPineconeInfo(item_new)
    assert out_new[rec.overall_rating_key] == "bad"

    item_plain = {
        rec.title_key: "n",
        rec.description_key: "d",
        rec.id_key: "t1",
        rec.overall_rating_key: 4,
        rec.image_key: "img",
        rec.api_review_count_key: "",
        rec.genres_key: "z",
        rec.release_date_key: "2021",
        rec.creator_key: "c",
    }
    out_plain = await rec.getMediaFromPineconeInfo(item_plain)
    assert out_plain == []


async def test_weigh_similar_media_scores(monkeypatch):
    async def _from_pin(item):
        return _media(item["id"], genres=["a", "b"], rating=4.0)

    monkeypatch.setattr(
        rec, "getMediaFromPineconeInfo", AsyncMock(side_effect=_from_pin)
    )

    out = await rec.weighSimilarMediaScores(
        {
            "similar_media_pinecone": [{"id": "m1", "score": 0.5}],
            "genres_liked": {"a"},
        }
    )

    assert len(out) == 1
    assert out[0][0][rec.id_key] == "m1"
    assert out[0][1] > 0


async def test_get_recommendations_from_vector_filters_excluded(monkeypatch):
    monkeypatch.setattr(
        rec,
        "collectSimilarMediaVector",
        AsyncMock(return_value=[{"id": "m1"}, {"id": "m2"}]),
    )
    monkeypatch.setattr(
        rec,
        "weighSimilarMediaScores",
        AsyncMock(return_value=[(_media("m1"), 0.8), (_media("m2"), 0.7)]),
    )

    out = await rec.getRecommendationsFromVector(
        {
            "amount": 5,
            "type": "m",
            "user_liked_vector": [1, 2],
            "exclude_ids": ["m2"],
            "genres_liked": {"drama"},
        }
    )
    assert [m[rec.id_key] for m in out] == ["m1"]


async def test_get_rec_for_vibe_search_all_and_single(monkeypatch):
    monkeypatch.setattr(
        rec,
        "collectSimilarMediaText",
        AsyncMock(return_value=[{"id": "m1", "score": 0.9}]),
    )
    monkeypatch.setattr(
        rec, "getMediaFromPineconeInfo", AsyncMock(return_value=_media("m1"))
    )

    out_all = await rec.getRecForVibeSearch({"text": "cozy", "type": "a", "amount": 2})
    out_single = await rec.getRecForVibeSearch(
        {"text": "cozy", "type": "m", "amount": 2}
    )

    assert len(out_all) == 3
    assert len(out_single) == 1


async def test_get_rec_for_media(monkeypatch):
    monkeypatch.setattr(rec, "getMediaUsingID", AsyncMock(return_value=_media("m1")))
    monkeypatch.setattr(
        rec.pinecone_logic,
        "getSimilarMediaUsingMedia",
        AsyncMock(
            return_value=[{"id": "m1", "score": 0.9}, {"id": "m2", "score": 0.8}]
        ),
    )
    monkeypatch.setattr(
        rec, "getMediaFromPineconeInfo", AsyncMock(return_value=_media("m2"))
    )

    out = await rec.getRecForMedia({rec.id_key: "m1", "type": "m", "amount": 5})
    assert out == [_media("m2")]


async def test_get_user_reviews_split(monkeypatch):
    monkeypatch.setattr(
        rec,
        "sendAsyncHttpRequestGet",
        AsyncMock(
            return_value=[
                ({rec.review_rating_key: 2}, _media("m1")),
                ({rec.review_rating_key: 5}, _media("b1")),
            ]
        ),
    )

    liked, disliked = await rec.getUserReviews("u1")
    assert len(liked) == 1
    assert len(disliked) == 1


async def test_get_user_reviews_vectorized(monkeypatch):
    async def _vec(media):
        return [{"id": media[rec.id_key], "values": [1, 2, 3]}]

    monkeypatch.setattr(
        rec.pinecone_logic, "getMediaUsingID", AsyncMock(side_effect=_vec)
    )
    out = await rec.getUserReviewsVectorized(
        [({"a": 1}, _media("m1")), ({"a": 2}, _media("m2"))]
    )
    assert len(out) == 2


async def test_clean_recommended_media_removes_reviewed_and_duplicates():
    rec_list = [_media("m1"), _media("m2"), _media("m2"), _media("m3")]
    review_vectors = [[{"id": "m1", "values": [1]}]]

    out = await rec.cleanRecommendedMedia(rec_list, review_vectors)
    assert [m[rec.id_key] for m in out] == ["m2", "m3"]


async def test_get_rec_for_cluster_user_reviews(monkeypatch):
    class DummyKMeans:
        def __init__(self, n_clusters, random_state):
            self.n_clusters = n_clusters

        def fit_predict(self, vectors):
            # Alternate labels so both buckets have content.
            return [i % self.n_clusters for i in range(len(vectors))]

    monkeypatch.setattr(rec, "KMeans", DummyKMeans)

    async def _collect(payload):
        return [{"id": f"{payload['type']}1", "score": 0.9}]

    monkeypatch.setattr(
        rec, "collectSimilarMediaVector", AsyncMock(side_effect=_collect)
    )
    monkeypatch.setattr(
        rec,
        "getMediaFromPineconeInfo",
        AsyncMock(side_effect=lambda item: _media(item["id"])),
    )

    review_vectors = [
        [{"id": "m-reviewed", "values": [1.0, 0.0]}],
        [{"id": "b-reviewed", "values": [0.0, 1.0]}],
    ]
    out = await rec.getRecForClusterUserReviews(
        review_vectors=review_vectors, types=["m", "b"]
    )
    assert len(out) >= 1
    assert all(rec.id_key in item for item in out)


async def test_get_rec_for_user(monkeypatch):
    monkeypatch.setattr(
        rec, "getUserReviews", AsyncMock(return_value=([({"r": 1}, _media("m1"))], []))
    )
    monkeypatch.setattr(
        rec,
        "getUserReviewsVectorized",
        AsyncMock(return_value=[[{"values": [1, 2, 3, 4]}]]),
    )
    monkeypatch.setattr(
        rec, "getRecForClusterUserReviews", AsyncMock(return_value=[_media("m9")])
    )

    out_all = await rec.getRecForUser({"uid": "u1", "type": "a", "amount": 10})
    out_one = await rec.getRecForUser({"uid": "u1", "type": "m", "amount": 10})

    assert out_all == [_media("m9")]
    assert out_one == [_media("m9")]
