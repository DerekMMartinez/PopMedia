import base64
import importlib.util
from pathlib import Path


from fastapi.testclient import TestClient




def _load_verify_api_module():
    verify_api_path = Path(__file__).resolve().parents[1] / "verify_api.py"
    spec = importlib.util.spec_from_file_location("verify_api_under_test", verify_api_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module




verify_api = _load_verify_api_module()




class _FakeVerifyModule:
    def __init__(self):
        self.initialized = False
        self.ensure_args = None
        self.verify_args = None
        self.ensure_exc = None
        self.verify_exc = None
        self.ensure_result = "cover text"
        self.verify_result = {
            "accepted": False,
            "reason": "similarity_low",
            "best_sim": 0.21,
            "ocr_score": 12,
            "inliers": 0,
            "composite_score": 0.21,
        }


    def initialize_service(self):
        self.initialized = True


    def ensure_item_in_index(self, item_id, canonical_image_url, metadata):
        if self.ensure_exc:
            raise self.ensure_exc
        self.ensure_args = {
            "item_id": item_id,
            "canonical_image_url": canonical_image_url,
            "metadata": metadata,
        }
        return self.ensure_result


    def verify(self, photo_path, metadata, cover_text):
        if self.verify_exc:
            raise self.verify_exc
        self.verify_args = {
            "photo_path": photo_path,
            "metadata": metadata,
            "cover_text": cover_text,
        }
        return self.verify_result




def _payload(**overrides):
    image_b64 = base64.b64encode(b"fake-jpg-bytes").decode("ascii")
    data = {
        "canonical_image_url": "https://example.com/canon.jpg",
        "user_image_base64": image_b64,
        "metadata": {"id": "42", "name": "Interstellar"},
        "uid": "user-1",
    }
    data.update(overrides)
    return data




def test_verify_image_match_success_rejected(monkeypatch):
    fake_verify = _FakeVerifyModule()
    monkeypatch.setattr(verify_api, "_verify_module", fake_verify)
    put_calls = []
    monkeypatch.setattr(
        verify_api.requests,
        "put",
        lambda *args, **kwargs: put_calls.append((args, kwargs)),
    )


    with TestClient(verify_api.app) as client:
        res = client.post("/verifyImageMatch", json=_payload())


    assert fake_verify.initialized is True
    assert res.status_code == 200
    body = res.json()
    assert body["media_id"] == "42"
    assert body["accepted"] is False
    assert body["reason"] == "similarity_low"
    assert body["confidence"] == 0.21
    assert fake_verify.ensure_args["item_id"] == "42"
    assert fake_verify.verify_args["cover_text"] == "cover text"
    assert put_calls == []




def test_verify_image_match_missing_metadata_id_returns_422(monkeypatch):
    fake_verify = _FakeVerifyModule()
    monkeypatch.setattr(verify_api, "_verify_module", fake_verify)


    with TestClient(verify_api.app) as client:
        res = client.post(
            "/verifyImageMatch",
            json=_payload(metadata={"name": "No ID"}),
        )


    assert res.status_code == 422
    assert res.json()["detail"] == "metadata.media_id is required"




def test_verify_image_match_ensure_index_failure_returns_400(monkeypatch):
    fake_verify = _FakeVerifyModule()
    fake_verify.ensure_exc = RuntimeError("download failed")
    monkeypatch.setattr(verify_api, "_verify_module", fake_verify)


    with TestClient(verify_api.app) as client:
        res = client.post("/verifyImageMatch", json=_payload())


    assert res.status_code == 400
    assert "Failed to ensure canonical index" in res.json()["detail"]




def test_verify_image_match_verify_failure_returns_500(monkeypatch):
    fake_verify = _FakeVerifyModule()
    fake_verify.verify_exc = RuntimeError("bad embedding")
    monkeypatch.setattr(verify_api, "_verify_module", fake_verify)


    with TestClient(verify_api.app) as client:
        res = client.post("/verifyImageMatch", json=_payload())


    assert res.status_code == 500
    assert "Verification failed: bad embedding" in res.json()["detail"]




def test_verify_image_match_accepted_currently_errors_on_metadata_name_attr(monkeypatch):
    fake_verify = _FakeVerifyModule()
    fake_verify.verify_result = {
        "accepted": True,
        "reason": "sim+ocr",
        "best_sim": 0.92,
        "ocr_score": 88,
        "inliers": 0,
        "composite_score": 0.92,
    }
    monkeypatch.setattr(verify_api, "_verify_module", fake_verify)
    post_calls = []
    monkeypatch.setattr(
        verify_api.requests,
        "post",
        lambda *args, **kwargs: post_calls.append((args, kwargs)) or None,
    )


    with TestClient(verify_api.app) as client:
        res = client.post("/verifyImageMatch", json=_payload())


    assert res.status_code == 200
    body = res.json()
    assert body["media_id"] == "42"
    assert body["accepted"] is True
    assert body["reason"] == "sim+ocr"
    assert body["confidence"] == 0.92
    assert len(post_calls) == 1
    args, kwargs = post_calls[0]
    assert kwargs["url"] == "https://api.thepopmedia.com/postMediaBadgeEarned"
    assert kwargs["params"] == {"media_id": "42", "uid": "user-1", "name": "Interstellar", "image_url": "https://example.com/canon.jpg"}