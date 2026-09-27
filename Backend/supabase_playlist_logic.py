import datacleaning


import standardmedia
import external_media_service
import cache_lock_logic
# ---------------------------------------------------------------------------------
# Standard Media Keys and Identifiers
# ---------------------------------------------------------------------------------
(
    title_key,
    description_key,
    overall_rating_key,
    id_key,
    image_key,
    api_review_count_key,
    genres_key,
    release_date_key,
    creator_key,
    media_length_key,
    season_count_key,
) = standardmedia.getStandardMediaKeys()
book_id_identifier, movie_id_identifier, tv_id_identifier = (
    standardmedia.getStandardMediaIdentifiers()
)
media_invalid_str_key, media_invalid_int_key = standardmedia.getInvalidMediaValues()


(
    review_uid_key,
    review_username_key,
    review_media_id_key,
    review_rating_key,
    review_text_key,
    review_visibility_key,
    review_finished_on_key,
    review_spoiler_key,
) = standardmedia.getStandardReviewKeys()


(
    review_uid_key,
    review_username_key,
    review_media_id_key,
    review_rating_key,
    review_text_key,
    review_visibility_key,
    review_finished_on_key,
    review_spoiler_key,
) = standardmedia.getStandardReviewKeys()
# ---------------------------------------------------------------------------------
# Supabase information
# ---------------------------------------------------------------------------------
from supabase_connection_logic import supabase

# -----------------------------------------------------------------------------------
# cache information
# -----------------------------------------------------------------------------------
from cachetools import TTLCache, LRUCache
from threading import RLock
from collections import defaultdict
import asyncio


def hourCalculator(minues: float) -> int:
    return int(minues * 60 * 60)


def minuteCalculator(minutes: float) -> int:
    return int(minutes * 60)


LRU_lock = RLock()  # Lock for synchronizing access to the LRU cache
LRU_cache = LRUCache(
    maxsize=1024
)  # Cache for ID search results (doesn't expire, just keeps the most recent 1024 searches)


TTL_lock = RLock()  # Lock for synchronizing access to the TTL cache
TTL_cache = TTLCache(maxsize=1024, ttl=minuteCalculator(15))  # Cache for 3 hours


# TRENDING_TTL_CACHE = TTLCache(maxsize=1024, ttl=hourCalculator(24)) # Cache for trending media for 1 hour
# TRENDING_LOCK = defaultdict(asyncio.Lock)  # Lock for synchronizing access to the trending media cache, using a defaultdict to create a new lock for each unique key


USER_PLAYLIST_LRU_CACHE = LRUCache(
    maxsize=1024
)  # Cache for user reviews, doesn't expire, just keeps the most recent 1024 searches
USER_PLAYLIST_LRU_LOCK = defaultdict(
    asyncio.Lock
)  # Lock for synchronizing access to the user review cache, using a defaultdict to create a new lock for each unique key


SUPABASE_GET_BOOK_CACHE = TTLCache(
    maxsize=1024, ttl=hourCalculator(3)
)  # Cache for getting book information from supabase, expires after 3 hours since book data can update more frequently
SUPABASE_GET_BOOK_LOCK = defaultdict(
    asyncio.Lock
)  # Lock for synchronizing access to the get book from supabase cache, using a defaultdict to create a new lock for each unique key


async def getPlaylists(uid: str) -> list:
    """
    Gets all playlist for a specific person from the database


    Returns a list of playlist dictionaries.
    """
    try:
        owned_playlists = (
            supabase.table("playlist_attributes")
            .select("*")  # or specify fields: "pid,name,description,image_url"
            .eq("uid", uid)
            .execute()
        )

        owned_data = owned_playlists.data

        collab_playlists = (
            supabase.table("playlist_collaborators")
            .select("playlist_attributes(*)")  # nested select
            .eq("uid", uid)
            .execute()
        )

        collab_data = [c["playlist_attributes"] for c in collab_playlists.data]

        all_playlists = owned_data + collab_data

        return all_playlists

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getPlaylists --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def deletePlaylist(pid: int):
    """
    Deletes a playlist from the playlist attributes table and associated rows in other playlist tables
    """

    try:
        (supabase.table("playlist_attributes").delete().eq("pid", pid).execute())

        return {"status": "ok"}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updatePlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def getCollaborators(pid: int, includeOwner: bool, ownerId: str) -> list:
    """
    Gets all the collaborator connected to a specific playlist based on pid and the owner id includeOwner is true


    Returns a list of collaborators (users) as dictionaries
    """
    try:
        collaborators = (
            supabase.table("playlist_collaborators")
            .select("users(*)")
            .eq("pid", pid)
            .execute()
        )

        collab_data = [c["users"] for c in collaborators.data]

        if includeOwner:
            owner = supabase.table("users").select("*").eq("uid", ownerId).execute()
            return owner.data + collab_data

        return collab_data

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getCollaborators --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def getPlaylistMediaCached(pid: int) -> list:
    """
    Gets all the media of the specified type connected to a specific playlist based on pid


    Returns a list of media as dictionaries
    """
    try:
        media_ids = (
            supabase.table("playlist_media").select("media_id").eq("pid", pid).execute()
        )
        media_type = 'a'

        medias = []
        for media_id in media_ids.data:
            media_str = media_id["media_id"]
            if media_type == "a":
                media_str = media_id["media_id"]
                media = await external_media_service.getMediaFromExternalAPIs(
                    request={
                        "mode": "id_search",
                        id_key: media_str,
                        "type": media_str[0],
                    }
                )
                medias.append(media[0])
            elif media_type == "m":
                media_str = media_id["media_id"]
                if media_str[0] != "m":
                    continue
                media = await external_media_service.getMediaFromExternalAPIs(
                    request={
                        "mode": "id_search",
                        id_key: media_str,
                        "type": media_str[0],
                    }
                )
                medias.append(media[0])
            elif media_type == "t":
                media_str = media_id["media_id"]
                if media_str[0] != "t":
                    continue
                media = await external_media_service.getMediaFromExternalAPIs(
                    request={
                        "mode": "id_search",
                        id_key: media_str,
                        "type": media_str[0],
                    }
                )
                medias.append(media[0])
            else:
                if media_str[0] != "b":
                    continue
                media_str = media_id["media_id"]
                media = await external_media_service.getMediaFromExternalAPIs(
                    request={
                        "mode": "id_search",
                        id_key: media_str,
                        "type": media_str[0],
                    }
                )
                medias.append(media[0])

        return medias


    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getPlaylistMedia --------------------------------"
        )
        print("message:", str(e))
        return {"status": "error", "message": str(e)}


PLAYLIST_MEDIA_CACHE = LRUCache(maxsize=10000)
PLAYLIST_MEDIA_LOCK = defaultdict(asyncio.Lock)

async def getPlaylistMedia(pid: int, media_type: str) -> list:
    args = (pid,)
    key = (pid,)

    results = await cache_lock_logic.cacheLockLogicLRU(
        args=args, 
        key=key, 
        CACHE=PLAYLIST_MEDIA_CACHE, 
        LOCK=PLAYLIST_MEDIA_LOCK, 
        function=getPlaylistMediaCached)
    
    filtered_results = datacleaning.filterMediaByType(media_list=results, media_type=media_type)

    return filtered_results


async def addMediaToPlaylist(pid: int, media_id: str):
    """
    Puts a media_id and pid row in the playlist media table
    """
    try:
        response = (
            supabase.table("playlist_media")
            .insert(
                {
                    "pid": pid,
                    "media_id": media_id,
                }
            )
            .execute()
        )

        if response.status_code == 201:
            args = (pid,)
            key = (pid,)
            await cache_lock_logic.repolulateCache(
                args=args,  # "a" for all media types, since
                key=key,
                CACHE=PLAYLIST_MEDIA_CACHE,
                LOCK=PLAYLIST_MEDIA_LOCK,
                function=getPlaylistMediaCached
            )
            return {"status": "ok"}

        raise Exception(f"Failed to add media to playlist, status code: {response.status_code}, response: {response.data}")
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE addMediaToPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def addCollaboratorToPlaylist(pid: int, uid: str):
    """
    Puts a uid and pid row in the playlist collaborator table
    """
    try:
        response = (
            supabase.table("playlist_collaborators")
            .insert(
                {
                    "pid": pid,
                    "uid": uid,
                }
            )
            .execute()
        )

        return {"status": "ok"}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE addCollaboratorToPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def deleteMediaFromPlaylist(pid: int, media_id: str):
    """
    Deletes a media_id and pid row in the playlist media table
    """
    try:
        response = (
            supabase.table("playlist_media")
            .delete()
            .eq("pid", pid)
            .eq("media_id", media_id)
            .execute()
        )


        if response.status_code == 201:
            args = (pid,)
            key = (pid,)
            await cache_lock_logic.repolulateCache(
                args=args,  # "a" for all media types, since
                key=key,
                CACHE=PLAYLIST_MEDIA_CACHE,
                LOCK=PLAYLIST_MEDIA_LOCK,
                function=getPlaylistMediaCached
            )
            return {"status": "ok"}

        raise Exception(f"Failed to delete media to playlist, status code: {response.status_code}, response: {response.data}")

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE deleteMediaFromPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def deleteCollaboratorFromPlaylist(pid: int, uid: str):
    """
    Deletes a uid and pid row in the playlist collaborator table
    """
    try:
        (
            supabase.table("playlist_collaborators")
            .delete()
            .eq("pid", pid)
            .eq("uid", uid)
            .execute()
        )

        return {"status": "ok"}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE deleteCollaboratorFromPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def postPlaylist(
    uid: str, name: str, description: str, image_url: str, public: bool
) -> int:
    """
    Posts a playlist to the playlist attributes table in the database and returns the pid


    Returns the pid as an int
    """

    try:
        response = (
            supabase.table("playlist_attributes")
            .insert(
                {
                    "uid": uid,
                    "name": name,
                    "description": description,
                    "image_url": image_url,
                    "public": public,
                }
            )
            .execute()
        )
        pid = response.data[0]["pid"]
        return pid

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postPlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def updatePlaylist(
    pid: int, uid: str, name: str, description: str, image_url: str, public: bool
) -> int:
    """
    Updates a playlist in the playlist attributes table in the database and returns the pid


    Returns the pid as an int
    """

    try:
        response = (
            supabase.table("playlist_attributes")
            .update(
                {
                    "uid": uid,
                    "name": name,
                    "description": description,
                    "image_url": image_url,
                    "public": public,
                }
            )
            .eq("pid", pid)
            .execute()
        )

        pid = response.data[0]["pid"]
        return pid

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE updatePlaylist --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def getPlaylistsUsingSearch(query: dict) -> list:
    """
    Gets a list of playlists from the Supabase database that fit the given request criteria


    query are of form:
        - input: str (the user's search input)
    """
    # validate and clean the user input
    user_input = datacleaning.validateUserInput(query["input"])

    # if the user's input is invalid, return empty list
    if user_input == "":
        return []

    response = (
        supabase.table("playlist_attributes")
        .select("*")
        .ilike("name", f"%{user_input}%")
        .eq("public", True)
        .limit(20)
        .execute()
    )

    return response.data
