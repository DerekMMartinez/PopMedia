import asyncio
import inspect
import os

import pinecone

# Prevent import-time Pinecone configuration failures during pytest collection.
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


# Ensure Backend imports can initialize Pinecone without external credentials/network.
pinecone.Pinecone = _DummyPinecone


def pytest_pyfunc_call(pyfuncitem):
    testfunction = pyfuncitem.obj
    if inspect.iscoroutinefunction(testfunction):
        sig = inspect.signature(testfunction)
        kwargs = {
            name: value
            for name, value in pyfuncitem.funcargs.items()
            if name in sig.parameters
        }
        asyncio.run(testfunction(**kwargs))
        return True
    return None
