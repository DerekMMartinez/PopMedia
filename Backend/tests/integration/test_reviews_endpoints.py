from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_delete_user_review_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "deleteUserReview",
        return_value={"status": "ok"},
    )

    response = client.get(
        "/deleteUserReview",
        params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2", "media_id": "123"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_reviews_from_media_api_success(mocker):
    mocker.patch.object(
        controller.external_media_service,
        "getReviewsFromMediaAPI",
        return_value=[{"username": "testuser", "review": "review text", "rating": "1"}],
    )

    response = client.get(
        "/getReviewsFromMediaAPI",
        params={"media_id": "123"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_following_media_reviews_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )
    mocker.patch.object(
        controller.supabase_review_logic,
        "getFollowingMediaReviews",
        return_value=[{"username": "testuser", "review": "review text", "rating": "1"}],
    )

    response = client.get(
        "/getFollowingMediaReviews",
        params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2", "type": "a"},
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_user_media_reviews_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "getUserMediaReview",
        return_value=[{"username": "testuser", "review": "review text", "rating": "1"}],
    )

    response = client.get(
        "/getUserMediaReviews",
        params={
            "request_uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "target_uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "type": "a",
        },
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_media_reviews_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "getMediaReviews",
        return_value=[{"username": "testuser", "review": "review text", "rating": "1"}],
    )

    response = client.get("/getMediaReviews", params={"media_id": "123"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_review_count_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic, "getReviewCount", return_value=1
    )

    response = client.get(
        "/getReviewCount", params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}
    )

    assert response.status_code == 200
    assert response.json() == 1


def test_book_rating_info_success(mocker):
    mocker.patch.object(
        controller.external_media_service,
        "getBookRatingInfo",
        return_value=(4, "reviews"),
    )

    response = client.get("/getBookRatingInfo", params={"book_id": "123"})

    assert response.status_code == 200
    assert response.json()[0] == 4


def test_update_user_review_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_review_logic,
        "updateUserReview",
        return_value={"review": "updated review"},
    )

    response = client.post(
        "/updateUserReview",
        json={
            "uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "review": "review test",
            "rating": "1",
        },
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert response.json()["review"] == "updated review"


def test_update_user_review_admin_success(mocker):
    mocker.patch.object(
        controller, "validateUserViaCredentials", return_value="bbdsacbadlcb"
    )

    mocker.patch.object(
        controller.supabase_review_logic,
        "updateUserReview",
        return_value={"review": "updated review"},
    )

    mocker.patch.object(controller.supabase_user_logic, "getAdmin", return_value=True)

    response = client.post(
        "/updateUserReview",
        json={
            "uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "review": "review test",
            "rating": "1",
        },
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert response.json()["review"] == "updated review"


def test_post_user_review_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "postUserReview",
        return_value={"review": "review"},
    )

    response = client.post(
        "/postUserReview",
        json={
            "uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "review": "review test",
            "rating": "1",
        },
    )

    assert response.status_code == 200
    assert response.json()["review"] == "review"
