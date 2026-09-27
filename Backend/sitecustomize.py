"""Pytest startup hooks for Backend test isolation."""

from __future__ import annotations

import os
import sys
import types


def _is_pytest_run() -> bool:
    return any("pytest" in arg for arg in sys.argv)


if _is_pytest_run():
    os.environ.setdefault("PINECONE_API_KEY", "test-pinecone-api-key")

    class _DummyPineconeIndex:
        def fetch(self, **_kwargs):
            return {"vectors": {}}

        def query(self, **_kwargs):
            return {"matches": []}

        def upsert(self, **_kwargs):
            return None

    class _DummyPineconeInference:
        def embed(self, **_kwargs):
            return {"data": []}

    class _DummyPinecone:
        def __init__(self, _api_key):
            self.inference = _DummyPineconeInference()

        def Index(self, _name):
            return _DummyPineconeIndex()

    pinecone_stub = types.ModuleType("pinecone")
    pinecone_stub.Pinecone = _DummyPinecone
    sys.modules["pinecone"] = pinecone_stub
