from fastapi import HTTPException


import datacleaning
import cache_lock_logic
from collections import defaultdict
import asyncio

# -----------------------------------------------------------------------------------
# cache information
# -----------------------------------------------------------------------------------
from cachetools import LRUCache


def hourCalculator(minues: float) -> int:
    return int(minues * 60 * 60)


def minuteCalculator(minutes: float) -> int:
    return int(minutes * 60)


USER_FOLLOWING_CACHE = LRUCache(maxsize=10000)
USER_FOLLOWING_LOCK = defaultdict(asyncio.Lock)

USER_FOLLOWERS_CACHE = LRUCache(maxsize=10000)
USER_FOLLOWERS_LOCK = defaultdict(asyncio.Lock)

GET_USERNAME_CACHE = LRUCache(maxsize=10000)
GET_USERNAME_LOCK = defaultdict(asyncio.Lock)


# ---------------------------------------------------------------------------------
# Supabase information
# ---------------------------------------------------------------------------------
from supabase_connection_logic import supabase


async def createNewFollow(user_id: str, following_id: str):
    try:
        #    print(f'--------- IN TRY CATCH createNewFollow: user_id: {user_id}, following_id: {following_id} ------------')
        supabase.table("following").upsert(
            {"user_id": user_id, "following_id": following_id}
        ).execute()

        args_following = (user_id,)
        key_following = (user_id,)
        await cache_lock_logic.repolulateCache(
            args=args_following,
            key=key_following,
            CACHE=USER_FOLLOWING_CACHE,
            LOCK=USER_FOLLOWING_LOCK,
            function=fetchFollowingCached,
        )

        args_followers = (following_id,)
        key_followers = (following_id,)
        await cache_lock_logic.repolulateCache(
            args=args_followers,
            key=key_followers,
            CACHE=USER_FOLLOWERS_CACHE,
            LOCK=USER_FOLLOWERS_LOCK,
            function=fetchFollowersCached,
        )

        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


async def deleteFollow(user_id: str, following_id: str):
    try:
        result = (
            supabase.table("following")
            .delete()
            .eq("user_id", user_id)
            .eq("following_id", following_id)
            .execute()
        )

        args_following = (user_id,)
        key_following = (user_id,)
        await cache_lock_logic.repolulateCache(
            args=args_following,
            key=key_following,
            CACHE=USER_FOLLOWING_CACHE,
            LOCK=USER_FOLLOWING_LOCK,
            function=fetchFollowingCached,
        )
        args_followers = (following_id,)
        key_followers = (following_id,)
        await cache_lock_logic.repolulateCache(
            args=args_followers,
            key=key_followers,
            CACHE=USER_FOLLOWERS_CACHE,
            LOCK=USER_FOLLOWERS_LOCK,
            function=fetchFollowersCached,
        )
        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def checkFollow(user_id: str, following_id: str):
    try:
        res = (
            supabase.table("following")
            .select("following_id")
            .eq("user_id", user_id)
            .eq("following_id", following_id)
            .execute()
        )
        print(res.data)
        if res.data is not None and len(res.data) > 0:
            return {"status": "ok", "is_following": True}
        else:
            return {"status": "ok", "is_following": False}

    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


async def fetchFollowingCached(user_id: str):
    """
    Fetches following for the given user id with caching logic

    NOTICE: THIS FUNCTION IS TYPICALLY CACHED, SO MAKE SURE TO CALL IT THROUGH THE cacheLockLogicLRU FUNCTION FOR IT TO WORK PROPERLY
    """
    try:
        print(
            "============= CACHING FOLLOWING, user_id: " + user_id + " =============="
        )
        # SPLIT join into 2 steps:
        # Step 1: get ids that this user follows
        res1 = (
            supabase.table("following")
            .select("following_id")
            .eq("user_id", user_id)
            .execute()
        )
        # list of users this user is FOLLOWING
        following_ids = [row["following_id"] for row in (res1.data or [])]

        if not following_ids:
            return []

        # Step 2: get full user rows.
        res2 = supabase.table("users").select("*").in_("uid", following_ids).execute()

        return res2.data

    except Exception as e:
        # Network / config / unexpected error
        print("Unexpected error:")
        print(e)
        raise


# returns all users that THIS user follows
# @cached(cache=TTL_cache, lock=TTL_lock)
async def fetchFollowing(user_id: str):
    args = (user_id,)
    key = (user_id,)
    result = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=USER_FOLLOWING_CACHE,
        LOCK=USER_FOLLOWING_LOCK,
        function=fetchFollowingCached,
    )
    return result


async def fetchFollowersCached(following_id: str):
    try:
        print(
            "============= CACHING FOLLOWERS, following_id: "
            + following_id
            + " =============="
        )
        # Step 1: get ids that follow this user
        res1 = (
            supabase.table("following")
            .select("user_id")
            .eq("following_id", following_id)
            .execute()
        )
        # list of users that are FOLLOWERs of this user
        follower_ids = [row["user_id"] for row in (res1.data or [])]

        if not follower_ids:
            return []

        # Step 2: get full user rows.
        res2 = supabase.table("users").select("*").in_("uid", follower_ids).execute()
        return res2.data

    except Exception as e:
        # Network / config / unexpected error
        print("Unexpected error:")
        print(e)
        raise


# returns all users that follow THIS user
# @cached(cache=TTL_cache, lock=TTL_lock)
async def fetchFollowers(following_id: str):

    args = (following_id,)
    key = (following_id,)
    result = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=USER_FOLLOWERS_CACHE,
        LOCK=USER_FOLLOWERS_LOCK,
        function=fetchFollowersCached,
    )
    return result


async def getUsernameCached(uid: str) -> dict:
    """
    Gets the username of a user based off of the uid

    Returns a dictionary with the username

    NOTICE: THIS METHOD IS TYPICALLY CACHED, SO MAKE SURE TO CALL IT THROUGH THE cacheLockLogicLRU FUNCTION FOR IT TO WORK PROPERLY
    """
    try:
        response = supabase.table("users").select("username").eq("uid", uid).execute()

        if response.data and len(response.data) > 0:
            return {
                "status": "success",
                "exists": True,
                "username": response.data[0]["username"],
            }
        else:
            return {"status": "success", "exists": False, "username": "does not exist"}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def getUsername(uid: str):
    """
    Gets the username of a user based off of the uid

    Returns a dictionary with the username
    """
    args = (uid,)
    key = (uid,)
    result = await cache_lock_logic.cacheLockLogicLRU(
        args=args,
        key=key,
        CACHE=GET_USERNAME_CACHE,
        LOCK=GET_USERNAME_LOCK,
        function=getUsernameCached,
    )
    return result



def getUser(uid: str):

    response = supabase.table("users").select("*").eq("uid", uid).execute()
    return response.data



def getUserUsingUsername(username: str):
    """
    Gets a list of users from the Supabase database that fit the given request criteria

    query are of form:
        - input: str (the user's search input)
    """
    # validate and clean the user input
    user_input = datacleaning.validateUserInput(username)

    # if the user's input is invalid, return empty list
    if user_input == "":
        return []

    response = (
        supabase.table("users")
        .select("*")
        # .ilike("username", f"%{user_input}%")
        .or_(f"username.ilike.%{user_input}%, name.ilike.%{user_input}%")
        .limit(20)
        .execute()
    )

    return response.data


async def getUsersUsingSearch(query: dict) -> list:
    """
    Gets a list of users from the Supabase database that fit the given request criteria

    query are of form:
        - input: str (the user's search input)
    """
    return getUserUsingUsername(query["input"])



def checkUsernameTaken(username: str, email: str):
    # print("PRE RESPONSE CHECKPOINT: username to check: " + username)
    response_username = (
        supabase.table("users").select("username").eq("username", username).execute()
    )

    response_email = (
        supabase.table("users")
        .select("email")
        .eq("username", username)
        .eq("email", email)
        .execute()
    )
    print(
        f"CHECKPOINT: response_username: {response_username.data}, response_email: {response_email.data}"
    )
    if response_email.data and len(response_email.data) > 0:
        return {"exists": "false"}

    if len(response_username.data) > 0:  # or len(response_email.data) > 0:
        return {"exists": "true"}

    else:
        return {"exists": "false"}


async def postNewUser(user: dict):
    """
    Adds a new user to the supabase database using the information provided in the user dictionary

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        response = (
            supabase.table("users")
            .upsert(
                {
                    "uid": user["uid"],
                    "username": user["username"],
                    "email": user["email"],
                    "name": user["name"],
                    "bio": user["bio"],
                    "profile_pic_url": user["profile_pic_url"],
                }
            )
            .execute()
        )

        args = (user["uid"],)
        key = (user["uid"],)
        await cache_lock_logic.repolulateCache(
            args=args,
            key=key,
            CACHE=GET_USERNAME_CACHE,
            LOCK=GET_USERNAME_LOCK,
            function=getUsernameCached,
        )
        return {"status": "success", "table": "users"}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postNewUser --------------------------------"
        )
        return {"status": "error", "message": str(e)}


def getCheckUser(uid: str):
    """
    Checks that a user with that id is in the supabase database

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        response = supabase.table("users").select("uid").eq("uid", uid).execute()

        if response.data and len(response.data) > 0:
            return {"status": "success", "exists": True, "uid": uid}

        else:
            return {"status": "success", "exists": False, "uid": uid}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE  getCheckUser --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def getFriends(user_id: str):
    followings = await fetchFollowing(user_id)
    followers = await fetchFollowers(user_id)

    friends = []
    for following in followings:
        if following in followers:
            friends.append(following)

    return friends


def getAdmin(user_id: str):
    response = supabase.table("users").select("admin").eq("uid", user_id).execute()
    if len(response.data) > 0:
        if response.data[0]["admin"] == True:
            return True
        else:
            return False


def setUserProfilePicture(
    user_id: str,
    object_key: str,
    cloudfront_domain: str = "d21jyc5i6ygo3u.cloudfront.net",
):
    print(
        "setting profile pic for user_id=",
        user_id,
        "object_key=",
        object_key,
        "cloudfront_domain=",
        cloudfront_domain,
    )
    try:
        if cloudfront_domain:
            object_key = f"https://{cloudfront_domain}/{object_key}"
        supabase.table("users").update({"profile_pic_url": object_key}).eq(
            "uid", user_id
        ).execute()
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def getUserProfilePictureUrl(uid: str):
    try:
        response = (
            supabase.table("users").select("profile_pic_url").eq("uid", uid).execute()
        )

        if response.data and len(response.data) > 0:
            return {"profile_pic_url": response.data[0]["profile_pic_url"]}
        else:
            return {"profile_pic_url": None}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getUserProfilePictureUrl --------------------------------"
        )
        raise HTTPException(status_code=500, detail=str(e))


async def deleteUserPhoto(uid: str):
    try:
        supabase.table("users").update(
            {
                "profile_pic_url": "https://d21jyc5i6ygo3u.cloudfront.net/defaultProfilePic.jpg"
            }
        ).eq("uid", uid).execute()
        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def deleteAccount(uid: str):
    try:
        supabase.table("users").delete().eq("uid", uid).execute()
        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

