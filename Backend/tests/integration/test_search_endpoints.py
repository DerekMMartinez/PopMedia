from fastapi.testclient import TestClient
import controller
from controller import app

client = TestClient(app)


def test_search_book_endpoint_success(mocker):
    mocker.patch(
        "external_media_service.getMediaFromExternalAPIs",
        return_value=[{"title": "Test Book"}],
    )

    response = client.post("/getMediaUsingSearch", json={"input": "Test", "type": "b"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_search_movie_endpoint_success(mocker):
    mocker.patch(
        "external_media_service.getMediaFromExternalAPIs",
        return_value=[{"title": "Test Move"}],
    )

    response = client.post("/getMediaUsingSearch", json={"input": "Test", "type": "m"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_search_tv_endpoint_success(mocker):
    mocker.patch(
        "external_media_service.getMediaFromExternalAPIs",
        return_value=[{"title": "Test TV"}],
    )

    response = client.post("/getMediaUsingSearch", json={"input": "Test", "type": "t"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_search_endpoint_success(mocker):
    mocker.patch(
        "external_media_service.getMediaFromExternalAPIs",
        side_effect=[
            [{"title": "Test Movie"}],  # 1st call
            [{"title": "Test Book"}],  # 2nd call
            [{"title": "Test TV"}],  # 3rd call
        ],
    )

    response = client.post("/getMediaUsingSearch", json={"input": "Test", "type": "a"})

    assert response.status_code == 200
    assert len(response.json()) == 3


def test_id_search_movie_endpoint_success(mocker):
    mocker.patch(
        "external_media_service.getMediaFromExternalAPIs",
        return_value=[{"title": "Test Movie"}],
    )

    response = client.post(
        "/getMediaUsingIdSearch", json={"input": "Test", "type": "m", "media_id": "123"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_id_search_tv_endpoint_success(mocker):
    mocker.patch(
        "external_media_service.getMediaFromExternalAPIs",
        return_value=[{"title": "Test TV"}],
    )

    response = client.post(
        "/getMediaUsingIdSearch", json={"input": "Test", "type": "t", "media_id": "123"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_id_search_book_endpoint_success(mocker):
    mocker.patch(
        "external_media_service.getMediaFromExternalAPIs",
        return_value=[{"title": "Test Book"}],
    )

    response = client.post(
        "/getMediaUsingIdSearch", json={"input": "Test", "type": "b", "media_id": "123"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_discover_search_book_endpoint_success(mocker):
    mocker.patch(
        "controller.getMediaUsingSearch", return_value=[{"title": "Test Book"}]
    )

    response = client.post("/getDiscoverSearch", json={"input": "Test", "type": "b"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_discover_search_tv_endpoint_success(mocker):
    mocker.patch("controller.getMediaUsingSearch", return_value=[{"title": "Test TV"}])

    response = client.post("/getDiscoverSearch", json={"input": "Test", "type": "t"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_discover_search_novie_endpoint_success(mocker):
    mocker.patch(
        "controller.getMediaUsingSearch", return_value=[{"title": "Test Movie"}]
    )

    response = client.post("/getDiscoverSearch", json={"input": "Test", "type": "m"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_discover_search_user_endpoint_success(mocker):
    mocker.patch.object(
        controller.supabase_user_logic,
        "getUsersUsingSearch",
        return_value=[{"name": "Test User"}],
    )

    response = client.post("/getDiscoverSearch", json={"input": "Test", "type": "u"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_discover_search_user_endpoint_success(mocker):
    mocker.patch.object(
        controller.supabase_playlist_logic,
        "getPlaylistsUsingSearch",
        return_value=[{"name": "Test Playlist"}],
    )

    response = client.post("/getDiscoverSearch", json={"input": "Test", "type": "p"})

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_discover_search_endpoint_success(mocker):
    mocker.patch.object(
        controller,
        "getMediaUsingSearch",
        return_value=[
            {"title": "Test TV"},
            {"title": "Test Movie"},
            {"title": "Test Book"},
        ],
    )
    mocker.patch.object(
        controller.supabase_user_logic,
        "getUsersUsingSearch",
        return_value=[{"name": "Test User"}],
    )
    mocker.patch.object(
        controller.supabase_playlist_logic,
        "getPlaylistsUsingSearch",
        return_value=[{"name": "Test Playlist"}],
    )

    response = client.post("/getDiscoverSearch", json={"input": "Test", "type": "a"})

    assert response.status_code == 200
    assert len(response.json()) == 5
