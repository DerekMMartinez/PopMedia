from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_get_user_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_user_logic,
        "getUser",
        return_value=[{"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}],
    )

    response = client.get(
        "/getUser",
        params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"},
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert response.json()[0]["uid"] == "geaUR9fjZXefTXalmEcBGadwlvx2"


def test_post_new_user_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic,
        "postNewUser",
        return_value={"status": "success", "table": "users"},
    )

    response = client.post("/postNewUser", json={"username": "Test name"})

    assert response.status_code == 200
    assert response.json()["status"] == "success"


def test_get_check_user_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic,
        "getCheckUser",
        return_value={
            "status": "success",
            "exists": True,
            "uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
    )

    response = client.get(
        "/getCheckUser",
        params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"},
    )

    assert response.status_code == 200
    assert response.json()["exists"] is True


def test_delete_follow_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_user_logic, "deleteFollow", return_value={"status": "ok"}
    )

    response = client.post(
        "/deleteFollow",
        params={
            "user_id": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "following_id": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_check_follow_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_user_logic,
        "checkFollow",
        return_value={"status": "ok", "is_following": True},
    )

    response = client.get(
        "/checkFollow",
        params={
            "user_id": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "following_id": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert response.json()["is_following"] is True


def test_fetch_following_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_user_logic,
        "fetchFollowing",
        return_value=[{"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}],
    )

    response = client.get(
        "/fetchFollowing",
        params={"user_id": "geaUR9fjZXefTXalmEcBGadwlvx2"},
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_fetch_followers_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_user_logic,
        "fetchFollowers",
        return_value=[{"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}],
    )

    response = client.get(
        "/fetchFollowers",
        params={"following_id": "geaUR9fjZXefTXalmEcBGadwlvx2"},
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_create_new_follow_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_user_logic, "createNewFollow", return_value={"status": "ok"}
    )

    response = client.post(
        "/createNewFollow",
        params={
            "user_id": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "following_id": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_username_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic,
        "getUsername",
        return_value={
            "status": "success",
            "exists": True,
            "username": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
    )

    response = client.get(
        "/getUsername",
        params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"},
    )

    assert response.status_code == 200
    assert response.json()["exists"] is True


def test_delete_account_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic, "deleteAccount", return_value={"status": "ok"}
    )

    response = client.post(
        "/deleteAccount", params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_check_friendship_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic, "checkFriendship", return_value=True
    )

    response = client.get(
        "/checkFriendship",
        params={
            "uid1": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "uid2": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
    )

    assert response.status_code == 200
    assert response.json() == True


def test_check_friendship_fail(mocker):
    mocker.patch.object(
        controller.supabase_review_logic, "checkFriendship", return_value=False
    )

    response = client.get(
        "/checkFriendship",
        params={
            "uid1": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "uid2": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
    )

    assert response.status_code == 200
    assert response.json() == False


def test_check_username_taken_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic, "checkFriendship", return_value=True
    )

    response = client.get(
        "/checkFriendship",
        params={
            "uid1": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "uid2": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
    )

    assert response.status_code == 200
    assert response.json() == True


def test_check_username_taken_fail(mocker):
    mocker.patch.object(
        controller.supabase_review_logic, "checkFriendship", return_value=False
    )

    response = client.get(
        "/checkFriendship",
        params={
            "uid1": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "uid2": "geaUR9fjZXefTXalmEcBGadwlvx2",
        },
    )

    assert response.status_code == 200
    assert response.json() == False


def test_get_friends_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.supabase_user_logic,
        "getFriends",
        return_value=[{"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}],
    )

    response = client.get(
        "/getFriends",
        params={"user_id": "geaUR9fjZXefTXalmEcBGadwlvx2"},
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1
