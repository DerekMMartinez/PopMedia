from collections import defaultdict
from unittest.mock import AsyncMock
import asyncio
import os
import sys
import types

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


class FakeTTLCache(dict):
    def __init__(self, *args, **kwargs):
        super().__init__()


class FakeLRUCache(dict):
    def __init__(self, *args, **kwargs):
        super().__init__()


def _fake_cached(*args, **kwargs):
    def _decorator(fn):
        return fn

    return _decorator


sys.modules.setdefault(
    "cachetools",
    types.SimpleNamespace(
        TTLCache=FakeTTLCache, LRUCache=FakeLRUCache, cached=_fake_cached
    ),
)

import cache_lock_logic as cll


async def test_cache_lock_logic_ttl_cache_hit_returns_cached_value():
    cache = FakeTTLCache(maxsize=10, ttl=60)
    lock = defaultdict(asyncio.Lock)
    args = ("u1",)
    cache[args] = {"value": 123}

    fn = AsyncMock(return_value={"value": 999})
    result = await cll.cacheLockLogicTTL(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert result == {"value": 123}
    fn.assert_not_called()


async def test_cache_lock_logic_ttl_cache_miss_stores_value():
    cache = FakeTTLCache(maxsize=10, ttl=60)
    lock = defaultdict(asyncio.Lock)
    args = ("u1",)

    fn = AsyncMock(return_value={"status": "ok", "data": [1, 2]})
    result = await cll.cacheLockLogicTTL(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert result == {"status": "ok", "data": [1, 2]}
    assert cache[args] == {"status": "ok", "data": [1, 2]}
    fn.assert_awaited_once_with("u1")


async def test_cache_lock_logic_ttl_error_result_is_not_cached():
    cache = FakeTTLCache(maxsize=10, ttl=60)
    lock = defaultdict(asyncio.Lock)
    args = ("u1",)

    fn = AsyncMock(return_value={"status": "error", "message": "boom"})
    result = await cll.cacheLockLogicTTL(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert result == {"status": "error", "message": "boom"}
    assert args not in cache


async def test_cache_lock_logic_lru_cache_hit_returns_cached_value():
    cache = FakeLRUCache(maxsize=10)
    lock = defaultdict(asyncio.Lock)
    args = ("abc", 5)
    cache[args] = ["cached"]

    fn = AsyncMock(return_value=["fresh"])
    result = await cll.cacheLockLogicLRU(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert result == ["cached"]
    fn.assert_not_called()


async def test_cache_lock_logic_lru_cache_miss_stores_value():
    cache = FakeLRUCache(maxsize=10)
    lock = defaultdict(asyncio.Lock)
    args = (3, 4)

    fn = AsyncMock(return_value={"sum": 7})
    result = await cll.cacheLockLogicLRU(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert result == {"sum": 7}
    assert cache[args] == {"sum": 7}
    fn.assert_awaited_once_with(3, 4)


async def test_cache_lock_logic_lru_error_result_is_not_cached():
    cache = FakeLRUCache(maxsize=10)
    lock = defaultdict(asyncio.Lock)
    args = ("x",)

    fn = AsyncMock(return_value={"status": "error", "detail": "bad"})
    result = await cll.cacheLockLogicLRU(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert result == {"status": "error", "detail": "bad"}
    assert args not in cache


async def test_repopulate_cache_replaces_existing_value_on_success():
    cache = FakeTTLCache(maxsize=10, ttl=60)
    lock = defaultdict(asyncio.Lock)
    args = ("u1",)
    cache[args] = {"old": True}

    fn = AsyncMock(return_value={"new": True})
    await cll.repolulateCache(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert cache[args] == {"new": True}
    fn.assert_awaited_once_with("u1")


async def test_repopulate_cache_does_not_write_error_result():
    cache = FakeTTLCache(maxsize=10, ttl=60)
    lock = defaultdict(asyncio.Lock)
    args = ("u1",)
    cache[args] = {"existing": 1}

    fn = AsyncMock(return_value={"status": "error", "message": "fail"})
    await cll.repolulateCache(args=args, key=args, CACHE=cache, LOCK=lock, function=fn)

    assert cache[args] == {"existing": 1}
