from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_post_report_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic,
        "postReport",
        return_value={"status": "success", "table": "reports"},
    )

    response = client.post(
        "/postReport",
        params={
            "associated_id": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "type": "review",
            "reason": "spoiler",
            "reporter": "kjkvaljbasljbvkrajbv",
            "created_at": "05_01_26",
            "resolved": False,
        },
    )

    assert response.status_code == 200
    assert response.json()["status"] == "success"


def test_resolve_report_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic, "resolveReport", return_value={"status": "ok"}
    )

    response = client.post("/resolveReport", params={"issue_id": "3", "resolved": True})

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_get_review_from_report_success(mocker):
    mocker.patch.object(
        controller.supabase_review_logic,
        "getReviewMediaFromReport",
        return_value=[{"username": "testuser", "review": "review text", "rating": "1"}],
    )

    response = client.get(
        "/getReviewFromReport", params={"associated_id": "geaUR9fjZXefTXalmEcBGadwlvx2"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_report_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic,
        "getReport",
        return_value=[{"user": "testuser", "reason": "spoiler"}],
    )

    response = client.get("/getReport", params={"resolved": True})

    assert response.status_code == 200
    assert len(response.json()) == 1
