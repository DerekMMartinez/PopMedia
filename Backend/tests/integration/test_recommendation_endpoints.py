from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_get_recommendations_for_user_success(mocker):
    mocker.patch.object(
        controller,
        "sendAsyncHttpRequestPost",
        return_value=[{"media": "media1"}, {"media": "media2"}],
    )

    response = client.post(
        "/getRecommendationsForUser", json={"uid": "ibvabfv", "type": "b"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 2


def test_get_recommendations_for_media_success(mocker):
    mocker.patch.object(
        controller,
        "sendAsyncHttpRequestPost",
        return_value=[{"media": "media1"}, {"media": "media2"}],
    )

    response = client.post(
        "/getRecommendationsForMedia", json={"uid": "ibvabfv", "type": "b"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 2


def test_get_recommendations_for_vibe_search_success(mocker):
    mocker.patch.object(
        controller,
        "sendAsyncHttpRequestPost",
        return_value=[{"name": "test1"}, {"name": "test2"}],
    )

    response = client.post(
        "/getRecommendationsForVibeSearch",
        json={"text": "test", "uid": "ibvabfv", "type": "b"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 2


def test_get_trending_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "getTrending",
        return_value={
            "b": [{"media_id": "1223", "name": "media Name"}],
            "m": [],
            "t": [],
        },
    )

    response = client.post("/getTrending", json={"uid": "ibvabfv", "type": "b"})

    assert "b" in response.json()
    assert len(response.json()["b"]) == 1
