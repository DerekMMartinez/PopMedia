import asyncio

from cachetools import TTLCache, LRUCache
from collections import defaultdict

CACHE_LRU = LRUCache
CACHE_TTL = TTLCache
LOCK = defaultdict

async def cacheLockLogicTTL(args: tuple, key: tuple, CACHE: TTLCache, LOCK: defaultdict, function):
    """
    async function that implements cache logic with a lock for a TTLCache. It takes in the arguments for the function, the cache, the lock, and the function itself.
    It first acquires the lock for the given arguments, then checks if the result is in the cache.
    If it is, it returns the cached result. If not, it computes the result using the given function, stores it in the cache, and then returns it.

    args should be a tuple of the arguments for the function, and function should be an async function that takes in those arguments.
    """
    # Acquire the lock for the input
    async with LOCK[key]:
        # Check the cache
        if key in CACHE:
            return CACHE[key]
        # If not in cache, compute the value with the given function and unpacked arguments
        result = await function(*args)

        # not storing in cache if the result was an error.
        if "status" in result and result["status"] == "error":
            print(
                f"============= ERROR CACHING TTL, args: {args}, key: {key}, function: {function}, message: {result.get('message', 'Unknown error')} ======================================="
            )
            return result

        # Store the result in the cache
        CACHE[key] = result

        return result


async def cacheLockLogicLRU(args: tuple, key: tuple, CACHE: LRUCache, LOCK: defaultdict, function):
    """
    async function that implements cache logic with a lock for an LRUCache. It takes in the arguments for the function, the cache, the lock, and the function itself.
    It first acquires the lock for the given arguments, then checks if the result is in the cache.
    If it is, it returns the cached result. If not, it computes the result using the given function, stores it in the cache, and then returns it.

    args should be a tuple of the arguments for the function, and function should be an async function that takes in those arguments.
    """

    # Acquire the lock for the input
    async with LOCK[key]:
        # Check the cache
        if key in CACHE:
            return CACHE[key]
        # If not in cache, compute the value with the given function and unpacked arguments
        result = await function(*args)

        # not storing in cache if the result was an error.
        if "status" in result and result["status"] == "error":
            print(
                f"============= ERROR CACHING LRU, args: {args}, key: {key}, function: {function}, message: {result.get('message', 'Unknown error')} ======================================="
            )

            return result

        # Store the result in the cache
        CACHE[key] = result

        return result


async def repolulateCache(args: tuple, key: tuple, CACHE, LOCK, function):
    """
    Repopulates the cache of args with the given function
    """
    async with LOCK[key]:
        result = await function(*args)

        if "status" in result and result["status"] == "error":
            print(
                f"============= ERROR REPOLUATING CACHE, args: {args}, key: {key}, function: {function}, message: {result.get('message', 'Unknown error')} ======================================="
            )
            return

        # if args in CACHE:
        #     del CACHE[args]

        CACHE[key] = result
