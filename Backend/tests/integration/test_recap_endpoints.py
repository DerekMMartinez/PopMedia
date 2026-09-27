from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_get_annual_recap_data_for_user_success(mocker):
    mocker.patch.object(
        controller,
        "sendAsyncHttpRequestGet",
        return_value={"top actor": "actor", "top tv": "tv"},
    )

    response = client.get(
        "/getAnnualRecapDataForUser", params={"uid": "ibvabfv", "year": "2026"}
    )

    assert response.status_code == 200
    assert response.json()["top actor"] == "actor"


def test_get_season_reviews_for_user_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "getSeasonReviewsForUser",
        return_value=[{"season": 1, "review": "review yeah"}],
    )

    response = client.get(
        "/getSeasonReviewsForUser", params={"uid": "ibvabfv", "tv_id": 121}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_season_info_success(mocker):
    mocker.patch(
        "external_media_service.getSeasonInfoFromTMDB", return_value={"actor": "actor?"}
    )

    response = client.get(
        "/getSeasonInfo", params={"media_id": "ibvabfv", "season_number": 1}
    )

    assert response.status_code == 200
    assert response.json()["actor"] == "actor?"


def test_get_credits_media_season_success(mocker):
    mocker.patch(
        "external_media_service.getCreditsForMediaSeasonFromTMDB",
        return_value={"actor": "actor?"},
    )

    response = client.get(
        "/getCreditsForMediaSeason", params={"media_id": "ibvabfv", "season_number": 1}
    )

    assert response.status_code == 200
    assert response.json()["actor"] == "actor?"


def test_get_credits_media_success(mocker):
    mocker.patch(
        "external_media_service.getCreditsfromTMDB", return_value={"actor": "actor?"}
    )

    response = client.get("/getCreditsForMedia", params={"media_id": "ibvabfv"})

    assert response.status_code == 200
    assert response.json()["actor"] == "actor?"
