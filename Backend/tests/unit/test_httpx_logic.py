import os
import sys
import types
from unittest.mock import AsyncMock

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


class DummyTimeout:
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


class DummyAsyncClient:
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


sys.modules["httpx"] = types.SimpleNamespace(
    Timeout=DummyTimeout, AsyncClient=DummyAsyncClient
)


import httpx_logic as hl


class DummyResponse:
    def __init__(self, payload=None, exc=None):
        self._payload = {} if payload is None else payload
        self._exc = exc

    def raise_for_status(self):
        if self._exc is not None:
            raise self._exc

    def json(self):
        return self._payload


class DummyClient:
    def __init__(self, response=None):
        self.response = response if response is not None else DummyResponse()
        self.post = AsyncMock(return_value=self.response)
        self.get = AsyncMock(return_value=self.response)


async def test_send_async_http_request_post_success():
    client = DummyClient(DummyResponse(payload={"ok": True}))

    result = await hl.sendAsyncHttpRequestPost(
        client, "https://example.com/post", {"a": 1}
    )

    assert result == {"ok": True}
    client.post.assert_awaited_once_with("https://example.com/post", json={"a": 1})


async def test_send_async_http_request_post_raises_status_error():
    client = DummyClient(DummyResponse(exc=RuntimeError("bad status")))

    with pytest.raises(RuntimeError, match="bad status"):
        await hl.sendAsyncHttpRequestPost(client, "https://example.com/post", {"a": 1})

    client.post.assert_awaited_once_with("https://example.com/post", json={"a": 1})


async def test_send_async_http_request_get_success_without_headers():
    client = DummyClient(DummyResponse(payload={"items": [1, 2]}))

    result = await hl.sendAsyncHttpRequestGet(
        client, "https://example.com/get", {"q": "x"}
    )

    assert result == {"items": [1, 2]}
    client.get.assert_awaited_once_with("https://example.com/get", params={"q": "x"})


async def test_send_async_http_request_get_success_with_headers():
    client = DummyClient(DummyResponse(payload={"items": [3]}))

    result = await hl.sendAsyncHttpRequestGet(
        client,
        "https://example.com/get",
        {"q": "x"},
        headers={"Authorization": "Bearer token"},
    )

    assert result == {"items": [3]}
    client.get.assert_awaited_once_with(
        "https://example.com/get",
        params={"q": "x"},
        headers={"Authorization": "Bearer token"},
    )


async def test_send_async_http_request_get_raises_status_error():
    client = DummyClient(DummyResponse(exc=RuntimeError("boom")))

    with pytest.raises(RuntimeError, match="boom"):
        await hl.sendAsyncHttpRequestGet(client, "https://example.com/get", {"q": "x"})

    client.get.assert_awaited_once_with("https://example.com/get", params={"q": "x"})
