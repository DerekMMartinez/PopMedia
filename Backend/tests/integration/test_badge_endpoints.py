from fastapi.testclient import TestClient
from controller import app

client = TestClient(app)


def test_check_badge_earned_success(mocker):
    mocker.patch("supabase_badge_logic.checkBadgeEarned", return_value=True)

    response = client.get(
        "/checkBadgeEarned", params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2", "bid": "1"}
    )

    assert response.status_code == 200
    assert response.json() == True


def test_post_new_badge_earned_success(mocker):
    mocker.patch(
        "supabase_badge_logic.postNewBadgeEarned",
        return_value=({"badge": "test badge"}),
    )

    response = client.post(
        "/postNewBadgeEarned", json={"bid": "1", "uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_badge_count_success(mocker):
    mocker.patch("supabase_badge_logic.getBadgeCount", return_value=2)

    response = client.get(
        "/getBadgeCount", params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}
    )

    assert response.status_code == 200
    assert response.json() == 2


def test_get_badge_success(mocker):
    mocker.patch(
        "supabase_badge_logic.getBadgeFromId",
        return_value={"bid": "1", "name": "badge"},
    )

    response = client.get("/getBadge", params={"bid": "1"})

    assert response.status_code == 200
    assert response.json()["bid"] == "1"


def test_get_badges_earned_success(mocker):
    mocker.patch(
        "supabase_badge_logic.getBadgesEarned",
        return_value=[{"bid": "1", "name": "badge"}],
    )

    response = client.get("/getBadgesEarned", params={"uid": ""})

    assert response.status_code == 200
    assert len(response.json()) == 1
