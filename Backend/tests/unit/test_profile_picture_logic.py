import os
import sys
import types
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


class DummyHTTPException(Exception):
    def __init__(self, status_code=None, detail=None):
        super().__init__(detail)
        self.status_code = status_code
        self.detail = detail


class DummyClientError(Exception):
    pass


fastapi_mod = types.ModuleType("fastapi")
fastapi_mod.FastAPI = MagicMock
fastapi_mod.Depends = MagicMock()
fastapi_mod.HTTPException = DummyHTTPException
fastapi_mod.Header = MagicMock()
security_mod = types.ModuleType("fastapi.security")
security_mod.HTTPBearer = MagicMock
security_mod.HTTPAuthorizationCredentials = MagicMock
sys.modules["fastapi"] = fastapi_mod
sys.modules["fastapi.security"] = security_mod

pydantic_mod = types.ModuleType("pydantic")


class DummyBaseModel:
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


pydantic_mod.BaseModel = DummyBaseModel
sys.modules["pydantic"] = pydantic_mod

boto3_mod = types.ModuleType("boto3")
boto3_mod.client = MagicMock(return_value=MagicMock())
sys.modules["boto3"] = boto3_mod

botocore_exceptions = types.ModuleType("botocore.exceptions")
botocore_exceptions.ClientError = DummyClientError
sys.modules["botocore.exceptions"] = botocore_exceptions

sys.modules["supabase_user_logic"] = MagicMock()

sys.modules.pop("profile_picture_logic", None)
import profile_picture_logic as ppl

# Avoid leaking this temporary stub into other test modules.
sys.modules.pop("supabase_user_logic", None)


def _request(filename="avatar.jpg", method="put", picture_type="profile"):
    return SimpleNamespace(filename=filename, method=method, pictureType=picture_type)


@pytest.fixture(autouse=True)
def reset_module_state(monkeypatch):
    monkeypatch.setattr(ppl, "s3", MagicMock())
    monkeypatch.setattr(ppl, "BUCKET", "test-bucket")
    monkeypatch.setattr(ppl, "MAX_BYTES", 1024)
    monkeypatch.setattr(ppl, "CLOUDFRONT_DOMAIN", "")


def test_allowed_extension_accepts_supported_formats():
    assert ppl._allowed_extension("photo.jpg") is True
    assert ppl._allowed_extension("photo.JPEG") is True
    assert ppl._allowed_extension("cover.png") is True
    assert ppl._allowed_extension("art.webp") is True


def test_allowed_extension_rejects_missing_or_unsupported_extension():
    assert ppl._allowed_extension("photo") is False
    assert ppl._allowed_extension("photo.gif") is False


def test_make_object_key_uses_profile_prefix_and_lowercase_extension(monkeypatch):
    monkeypatch.setattr(ppl.uuid, "uuid4", lambda: SimpleNamespace(hex="abc123"))
    assert (
        ppl._make_object_key("user-1", "Photo.JPEG")
        == "users/user-1/profile/abc123.jpeg"
    )


def test_make_playlist_cover_key_uses_playlist_prefix(monkeypatch):
    monkeypatch.setattr(ppl.uuid, "uuid4", lambda: SimpleNamespace(hex="xyz789"))
    assert (
        ppl._make_playlist_cover_key("user-1", "cover.PNG")
        == "users/user-1/playlist/xyz789.png"
    )


def test_sign_upload_rejects_invalid_extension():
    with pytest.raises(DummyHTTPException) as exc_info:
        ppl.sign_upload("user-1", _request(filename="avatar.gif"))

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "File extension not allowed"


def test_sign_upload_returns_presigned_put_for_profile_picture(monkeypatch):
    monkeypatch.setattr(
        ppl,
        "_make_object_key",
        lambda user_id, filename: f"users/{user_id}/profile/fixed.jpeg",
    )
    ppl.s3.generate_presigned_url.return_value = "https://signed-put"
    monkeypatch.setattr(ppl, "CLOUDFRONT_DOMAIN", "cdn.example.com")

    result = ppl.sign_upload(
        "user-1", _request(filename="avatar.jpg", method="put", picture_type="profile")
    )

    assert result == {
        "method": "put",
        "uploadUrl": "https://signed-put",
        "objectKey": "users/user-1/profile/fixed.jpeg",
        "cdnUrl": "https://cdn.example.com/users/user-1/profile/fixed.jpeg",
    }
    ppl.s3.generate_presigned_url.assert_called_once_with(
        "put_object",
        Params={
            "Bucket": "test-bucket",
            "Key": "users/user-1/profile/fixed.jpeg",
            "ContentType": "image/jpeg",
        },
        ExpiresIn=900,
    )


def test_sign_upload_returns_presigned_post_for_playlist_picture(monkeypatch):
    monkeypatch.setattr(
        ppl,
        "_make_playlist_cover_key",
        lambda user_id, filename: f"users/{user_id}/playlist/fixed.webp",
    )
    ppl.s3.generate_presigned_post.return_value = {
        "url": "https://signed-post",
        "fields": {"key": "value"},
    }

    result = ppl.sign_upload(
        "user-2",
        _request(filename="cover.webp", method="post", picture_type="playlist"),
    )

    assert result == {
        "method": "post",
        "uploadData": {"url": "https://signed-post", "fields": {"key": "value"}},
        "objectKey": "users/user-2/playlist/fixed.webp",
        "cdnUrl": None,
    }
    ppl.s3.generate_presigned_post.assert_called_once_with(
        Bucket="test-bucket",
        Key="users/user-2/playlist/fixed.webp",
        Fields={
            "Content-Type": "image/webp",
            "key": "users/user-2/playlist/fixed.webp",
        },
        Conditions=[
            ["content-length-range", 0, 1024],
            {"Content-Type": "image/webp"},
        ],
        ExpiresIn=900,
    )


def test_confirm_upload_requires_object_key():
    with pytest.raises(DummyHTTPException) as exc_info:
        ppl.confirm_upload("user-1", {})

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Missing objectKey"


def test_confirm_upload_rejects_mismatched_user_prefix():
    with pytest.raises(DummyHTTPException) as exc_info:
        ppl.confirm_upload("user-1", {"objectKey": "users/other-user/profile/file.jpg"})

    assert exc_info.value.status_code == 403
    assert exc_info.value.detail == "Object key mismatch"


def test_confirm_upload_raises_when_s3_object_missing():
    ppl.s3.head_object.side_effect = DummyClientError("missing")

    with pytest.raises(DummyHTTPException) as exc_info:
        ppl.confirm_upload("user-1", {"objectKey": "users/user-1/profile/file.jpg"})

    assert exc_info.value.status_code == 400
    assert "Uploaded object not found" in exc_info.value.detail


def test_confirm_upload_rejects_oversized_file():
    ppl.s3.head_object.return_value = {
        "ContentLength": 2048,
        "ContentType": "image/jpeg",
    }

    with pytest.raises(DummyHTTPException) as exc_info:
        ppl.confirm_upload("user-1", {"objectKey": "users/user-1/profile/file.jpg"})

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Uploaded file is too large"


def test_confirm_upload_rejects_invalid_content_type():
    ppl.s3.head_object.return_value = {
        "ContentLength": 512,
        "ContentType": "application/pdf",
    }

    with pytest.raises(DummyHTTPException) as exc_info:
        ppl.confirm_upload("user-1", {"objectKey": "users/user-1/profile/file.jpg"})

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Invalid content type"


def test_confirm_upload_returns_true_and_object_key_for_valid_upload():
    ppl.s3.head_object.return_value = {"ContentLength": 512, "ContentType": "image/png"}

    result = ppl.confirm_upload(
        "user-1", {"objectKey": "users/user-1/profile/file.png"}
    )

    assert result == (True, "users/user-1/profile/file.png")
    ppl.s3.head_object.assert_called_once_with(
        Bucket="test-bucket", Key="users/user-1/profile/file.png"
    )


def test_get_presigned_get_returns_url():
    ppl.s3.generate_presigned_url.return_value = "https://signed-get"

    result = ppl.get_presigned_get("users/user-1/profile/file.png", 60)

    assert result == {"url": "https://signed-get"}
    ppl.s3.generate_presigned_url.assert_called_once_with(
        "get_object",
        Params={"Bucket": "test-bucket", "Key": "users/user-1/profile/file.png"},
        ExpiresIn=60,
    )


def test_get_presigned_get_wraps_errors_in_http_exception():
    ppl.s3.generate_presigned_url.side_effect = RuntimeError("cannot sign")

    with pytest.raises(DummyHTTPException) as exc_info:
        ppl.get_presigned_get("users/user-1/profile/file.png", 60)

    assert exc_info.value.status_code == 400
    assert "Cannot create presigned URL" in exc_info.value.detail
