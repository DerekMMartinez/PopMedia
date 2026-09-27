from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_get_season_reviews_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "getSeasonReviews",
        return_value=[{"review_id": "1"}],
    )

    response = client.get(
        "/getSeasonReviews",
        params={"review_id": "1"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_update_season_review_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "updateSeasonReview",
        return_value={"review": "Test review"},
    )

    response = client.post("/updateSeasonReview", json={"review": "Test review"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_delete_season_review_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "deleteSeasonReview",
        return_value={"review": "Test review"},
    )

    response = client.post(
        "/deleteSeasonReview", params={"rid": "1", "season_number": "1"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_gete_tv_season_count_success(mocker):
    mocker.patch.object(
        controller.external_media_service, "getTvSeasonCount", return_value=2
    )

    response = client.get("/getTvSeasonCount", params={"media_id": "1"})

    assert response.status_code == 200
    assert response.json() == 2
