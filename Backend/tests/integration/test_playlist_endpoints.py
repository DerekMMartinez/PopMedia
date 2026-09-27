from fastapi.testclient import TestClient
from controller import app

client = TestClient(app)


def test_post_playlist_success(mocker):
    mocker.patch("supabase_playlist_logic.postPlaylist", return_value=1)

    response = client.post(
        "/postPlaylist",
        params={
            "uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "name": "pname",
            "description": "fun",
            "image_url": "url",
            "public": False,
        },
    )

    assert response.status_code == 200
    assert response.json() == 1


def test_update_playlist_success(mocker):
    mocker.patch("supabase_playlist_logic.updatePlaylist", return_value=1)

    response = client.post(
        "/updatePlaylist",
        params={
            "pid": 1,
            "uid": "geaUR9fjZXefTXalmEcBGadwlvx2",
            "name": "pname",
            "description": "fun",
            "image_url": "url",
            "public": False,
        },
    )

    assert response.status_code == 200
    assert response.json() == 1


def test_delete_playlist_success(mocker):
    mocker.patch("supabase_playlist_logic.deletePlaylist", return_value=True)

    response = client.post("/deletePlaylist", params={"pid": 1})

    assert response.status_code == 200
    assert response.json() == True


def test_add_media_to_playlist_success(mocker):
    mocker.patch("supabase_playlist_logic.addMediaToPlaylist", return_value=True)

    response = client.post("/addMediaToPlaylist", params={"pid": 1, "media_id": "123"})

    assert response.status_code == 200
    assert response.json() == True


def test_add_collaborator_to_playlist_success(mocker):
    mocker.patch("supabase_playlist_logic.addCollaboratorToPlaylist", return_value=True)

    response = client.post(
        "/addCollaboratorToPlaylist",
        params={"pid": 1, "uid": "geaUR9fjZXefTXalmEcBGadwlvx2"},
    )

    assert response.status_code == 200
    assert response.json() == True


def test_delete_media_from_playlist_success(mocker):
    mocker.patch("supabase_playlist_logic.deleteMediaFromPlaylist", return_value=True)

    response = client.post(
        "/deleteMediaFromPlaylist", params={"pid": 1, "media_id": "123"}
    )

    assert response.status_code == 200
    assert response.json() == True


def test_delete_collaborator_from_playlist_success(mocker):
    mocker.patch(
        "supabase_playlist_logic.deleteCollaboratorFromPlaylist", return_value=True
    )

    response = client.post(
        "/deleteCollaboratorFromPlaylist",
        params={"pid": 1, "uid": "geaUR9fjZXefTXalmEcBGadwlvx2"},
    )

    assert response.status_code == 200
    assert response.json() == True


def test_get_playlists_success(mocker):
    mocker.patch(
        "supabase_playlist_logic.getPlaylists",
        return_value=[{"pid": "1", "name": "playlis"}],
    )

    response = client.get(
        "/getPlaylists", params={"uid": "geaUR9fjZXefTXalmEcBGadwlvx2"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_collaborators_success(mocker):
    mocker.patch(
        "supabase_playlist_logic.getCollaborators",
        return_value=[{"uid": "ijbvjfbvkj", "username": "testUser"}],
    )

    response = client.get(
        "/getCollaborators",
        params={"pid": 1, "includeOwner": True, "ownerId": "ibviaerbvc"},
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_playlist_media_success(mocker):
    mocker.patch(
        "supabase_playlist_logic.getPlaylistMedia",
        return_value=[{"media_id": "123", "name": "testMedia"}],
    )

    response = client.get("/getPlaylistMedia", params={"pid": 1, "media_type": "a"})

    assert response.status_code == 200
    assert len(response.json()) == 1
