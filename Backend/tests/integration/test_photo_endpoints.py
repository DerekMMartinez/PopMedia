from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_get_pre_signed_url_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.profile_picture_logic, "sign_upload", return_value="presigned"
    )

    response = client.post(
        "/getPreSignedUrl",
        json={"filename": "name.jpg"},
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert response.json() == "presigned"


def test_confirm_upload_success(mocker):
    mocker.patch.object(
        controller,
        "validateUserViaCredentials",
        return_value="geaUR9fjZXefTXalmEcBGadwlvx2",
    )

    mocker.patch.object(
        controller.profile_picture_logic,
        "confirm_upload",
        return_value=(True, "presigned"),
    )

    response = client.post(
        "/confirmUpload",
        json={"objectKey": "users/geaUR9fjZXefTXalmEcBGadwlvx2/profile/name.jpg"},
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_delete_user_photo_upload_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic, "deleteUserPhoto", return_value={"status": "ok"}
    )

    response = client.post(
        "/deleteUserPhoto",
        params={"uid": "jbfvjcbalcn"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
