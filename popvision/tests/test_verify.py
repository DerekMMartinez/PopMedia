import importlib.util
import sys
import types
from pathlib import Path

import numpy as np


def _load_verify_module(monkeypatch):
    # Stub heavy optional deps before importing verify.py
    torch_stub = types.SimpleNamespace(
        cuda=types.SimpleNamespace(is_available=lambda: False),
    )
    cv2_stub = types.SimpleNamespace(
        IMREAD_COLOR=1,
        COLOR_BGR2GRAY=1,
        NORM_HAMMING=6,
        RANSAC=8,
    )
    transformers_stub = types.SimpleNamespace(
        CLIPProcessor=types.SimpleNamespace(from_pretrained=lambda *a, **k: object()),
        CLIPModel=types.SimpleNamespace(from_pretrained=lambda *a, **k: object()),
    )
    fuzz_stub = types.SimpleNamespace(partial_ratio=lambda a, b: 0)
    rapidfuzz_stub = types.SimpleNamespace(fuzz=fuzz_stub)

    monkeypatch.setitem(sys.modules, "torch", torch_stub)
    monkeypatch.setitem(sys.modules, "cv2", cv2_stub)
    monkeypatch.setitem(sys.modules, "transformers", transformers_stub)
    monkeypatch.setitem(sys.modules, "rapidfuzz", rapidfuzz_stub)

    verify_path = Path(__file__).resolve().parents[1] / "verify.py"
    spec = importlib.util.spec_from_file_location("verify_under_test", verify_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_texts_from_paddle_results_filters_invalid(monkeypatch):
    verify = _load_verify_module(monkeypatch)

    results = [
        {"error": "boom"},
        {"rec_texts": ["Hello", "", None, "World"]},
        {"rec_texts": ["123"]},
        {},
        None,
    ]

    assert verify._texts_from_paddle_results(results) == ["Hello", "World", "123"]


def test_ocr_match_score_returns_zero_for_empty_inputs(monkeypatch):
    verify = _load_verify_module(monkeypatch)
    monkeypatch.setattr(verify.fuzz, "partial_ratio", lambda a, b: 99)

    assert verify.ocr_match_score("", "target") == 0
    assert verify.ocr_match_score("source", "") == 0


def test_verify_returns_no_canonical_when_item_missing(monkeypatch):
    verify = _load_verify_module(monkeypatch)
    monkeypatch.setattr(verify, "initialize_service", lambda: None)
    verify.item_to_rows = {}

    out = verify.verify(
        "photo.jpg",
        metadata={"id": "42", "42": {"name": "Interstellar"}},
        cover_text=None,
    )

    assert out == {"result": "no_canonical", "confidence": 0.0}


def test_verify_accepts_on_strong_ocr(monkeypatch):
    verify = _load_verify_module(monkeypatch)
    monkeypatch.setattr(verify, "initialize_service", lambda: None)
    monkeypatch.setattr(verify, "embed_image", lambda _: np.array([1.0, 0.0], dtype=np.float32))
    monkeypatch.setattr(verify, "extract_ocr_text", lambda _: "interstellar")
    monkeypatch.setattr(verify, "ocr_match_score", lambda _ocr, _target: 85)

    verify.item_to_rows = {"42": [0]}
    verify.embs = np.array([[0.1, 0.99]], dtype=np.float32)
    verify.metas = [{"filename": "canon.jpg", "item_id": "42"}]

    out = verify.verify("photo.jpg", metadata={"id": "42", "42": {"name": "Interstellar"}})

    assert out["accepted"] is True
    assert out["reason"] == "ocr_strong_match"
    assert out["ocr_score"] == 85


def test_verify_accepts_on_similarity_plus_ocr(monkeypatch):
    verify = _load_verify_module(monkeypatch)
    monkeypatch.setattr(verify, "initialize_service", lambda: None)
    monkeypatch.setattr(verify, "embed_image", lambda _: np.array([1.0, 0.0], dtype=np.float32))
    monkeypatch.setattr(verify, "extract_ocr_text", lambda _: "book")
    monkeypatch.setattr(verify, "ocr_match_score", lambda _ocr, _target: 70)

    verify.item_to_rows = {"7": [0]}
    verify.embs = np.array([[1.0, 0.0]], dtype=np.float32)  # cosine sim = 1.0
    verify.metas = [{"filename": "canon.jpg", "item_id": "7"}]

    out = verify.verify("photo.jpg", metadata={"id": "7", "7": {"name": "The Book"}})

    assert out["accepted"] is True
    assert out["reason"] == "sim+ocr"
    assert out["best_sim"] >= verify.SIMILARITY_ACCEPT_THRESHOLD


def test_verify_falls_back_to_geom_and_rejects_when_composite_low(monkeypatch):
    verify = _load_verify_module(monkeypatch)
    monkeypatch.setattr(verify, "initialize_service", lambda: None)
    monkeypatch.setattr(verify, "embed_image", lambda _: np.array([1.0, 0.0], dtype=np.float32))
    monkeypatch.setattr(verify, "extract_ocr_text", lambda _: "nomatch")
    monkeypatch.setattr(verify, "ocr_match_score", lambda _ocr, _target: 10)
    monkeypatch.setattr(verify, "geometric_verify", lambda _u, _c: 100)

    verify.item_to_rows = {"9": [0]}
    verify.embs = np.array([[0.2, 0.98]], dtype=np.float32)
    verify.metas = [{"filename": "canon.jpg", "item_id": "9"}]

    out = verify.verify("photo.jpg", metadata={"id": "9", "9": {"name": "Target"}})

    assert out["accepted"] is False
    assert out["reason"] == "similarity_low"
    assert out["inliers"] == 100
    assert out["composite_score"] < verify.SIMILARITY_ACCEPT_THRESHOLD


def test_verify_accepts_on_similarity_plus_geom(monkeypatch):
    verify = _load_verify_module(monkeypatch)
    monkeypatch.setattr(verify, "initialize_service", lambda: None)
    monkeypatch.setattr(verify, "embed_image", lambda _: np.array([1.0, 0.0], dtype=np.float32))
    monkeypatch.setattr(verify, "extract_ocr_text", lambda _: "nomatch")
    monkeypatch.setattr(verify, "ocr_match_score", lambda _ocr, _target: 20)
    monkeypatch.setattr(verify, "geometric_verify", lambda _u, _c: verify.INLIER_THRESHOLD)

    verify.item_to_rows = {"100": [0]}
    verify.embs = np.array([[0.7, 0.0]], dtype=np.float32)
    verify.metas = [{"filename": "canon.jpg", "item_id": "100"}]

    out = verify.verify("photo.jpg", metadata={"id": "100", "100": {"name": "Target"}})

    assert out["accepted"] is True
    assert out["reason"] == "sim+geom"
    assert out["composite_score"] >= verify.SIMILARITY_ACCEPT_THRESHOLD
