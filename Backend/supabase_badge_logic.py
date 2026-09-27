import standardmedia

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

# ---------------------------------------------------------------------------------
# Supabase information
# ---------------------------------------------------------------------------------
# load_dotenv()  # Load environment variables from .env file
# SUPABASE_API_URL = "https://lvtjyhigbynbhomsktjm.supabase.co"
# SUPABASE_API_KEY = os.getenv('SUPABASE_API_KEY')
# _supabase = None

# def get_supabase():
#     global _supabase
#     if _supabase is None:
#         _supabase = create_client(SUPABASE_API_URL, SUPABASE_API_KEY)
#     return _supabase
from supabase_connection_logic import supabase


def postNewBadgeEarned(badgeEarned: dict):
    """
    Adds a new badge_earned to the supabase database using the information provided in the badgeEarned dictionary

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """
    try:
        # First check if badge already exists
        existing = (
            supabase.table("badges_earned")
            .select("*")
            .eq("uid", badgeEarned["uid"])
            .eq("bid", badgeEarned["bid"])
            .execute()
        )

        if existing.data and len(existing.data) > 0:
            # Badge already earned, return success without inserting duplicate
            return {
                "status": "success",
                "table": "badges_earned",
                "message": "Badge already earned",
            }

        # Insert new badge
        response = (
            supabase.table("badges_earned")
            .insert(
                {
                    "bid": badgeEarned["bid"],
                    "uid": badgeEarned["uid"],
                    "earned_at": badgeEarned["earned_at"],
                }
            )
            .execute()
        )

        return {"status": "success", "table": "badges_earned"}
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postNewBadgeEarned --------------------------------"
        )
        print(f"Error: {e}")
        return {"status": "error", "message": str(e)}


def getBadgeCount(uid: str):
    response = (
        supabase.table("badges_earned")
        .select("*", count="exact")
        .eq("uid", uid)
        .execute()
    )
    print(
        f"---------------- badge count for uid {uid}: {response.count} -----------------"
    )
    sum = response.count or 0
    return sum


def getBadgesEarned(uid: str):
    """
    Gets all badges earned by a specific person from the database

    Returns a list of tuples with badge earned at 0 and the badge at 1.
    """
    try:
        response = supabase.table("badges_earned").select("*").eq("uid", uid).execute()

        badges = []

        for badge_earned in response.data:
            badge = getBadgeFromId(badge_earned["bid"])
            badges.append((badge_earned, badge[0]))

        return badges

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgesEarned --------------------------------"
        )
        return {"status": "error", "message": str(e)}


def getBadgeFromId(bid: str):
    """
    Gets a badge from the database based on the bid

    Returns a dictionary with the badge or empty.
    """
    try:
        response = supabase.table("badges").select("*").eq("bid", bid).execute()

        return response.data

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadge --------------------------------"
        )
        return {"status": "error", "message": str(e)}


async def checkBadgeEarned(uid: str, bid: str) -> bool:
    """
    Checks if a badge has already been earned by a user

    Returns true if the badge has already been earned, false if not, and an error message if there was an error.
    """
    try:
        response = (
            supabase.table("badges_earned")
            .select("*")
            .eq("uid", uid)
            .eq("bid", bid)
            .execute()
        )

        if response.data and len(response.data) > 0:
            return True
        else:
            return False

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE checkBadgeEarned --------------------------------"
        )
        print(f"Error: {str(e)}")
        return {"status": "error", "message": str(e)}


async def checkMediaBadgeExists(media_id: str) -> bool:
    try:
        response = (
            supabase.table("badges").select("*").eq("media_id", media_id).execute()
        )
        if response.data and len(response.data) > 0:
            return True
        else:
            return False
    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE checkMediaBadgeExists --------------------------------"
        )
        print(f"Error: {str(e)}")
        return {"status": "error", "message": str(e)}


async def checkMediaBadgeEarned(uid: str, media_id: str) -> bool:
    """
    Checks if a badge has already been earned by a user for a specific media

    Returns true if the badge has already been earned, false if not, and an error message if there was an error.
    """
    try:
        response1 = (
            supabase.table("badges").select("bid").eq("media_id", media_id).execute()
        )
        print(
            "Response from supabase when checking for badge with media_id "
            + media_id
            + ": "
            + str(response1.data)
        )
        if response1.data and len(response1.data) > 0:
            response2 = (
                supabase.table("badges_earned")
                .select("*")
                .eq("uid", uid)
                .eq("bid", response1.data[0]["bid"])
                .execute()
            )
            print(
                "Response from supabase when checking if badge with media_id "
                + media_id
                + " already earned for uid "
                + uid
                + ": "
                + str(response2.data)
            )
            if response2.data and len(response2.data) > 0:
                return True
            else:
                return False
        else:
            print(
                f"------------------ checkMediaBadgeEarned: No badge found for media_id: {media_id} ------------------"
            )

            return False

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE checkMediaBadgeEarned --------------------------------"
        )
        print(f"Error: {str(e)}")
        return {"status": "error", "message": str(e)}


async def createBadgeForMedia(media_id: str, name: str, image_url: str):
    """
    Creates a badge for a specific media with the provided badge information

    Returns a dictionary with the status of the operation and any relevant messages.
    """

    if media_id.startswith(book_id_identifier):
        media_type = "book"
    elif media_id.startswith(movie_id_identifier):
        media_type = "movie"
    elif media_id.startswith(tv_id_identifier):
        media_type = "show"
    try:
        response = (
            supabase.table("badges")
            .insert(
                {
                    "type": media_type,
                    "media_id": media_id,
                    "name": name,
                    "description": f'Scanned image for "{name}"!',
                    "image_url": image_url,
                    "how_to": "take a photo of this media to earn a badge for it!",
                }
            )
            .execute()
        )
        print("Supabase insert for new badge executed and returned:", response.data)
        return {"status": "success", "message": "Badge created successfully"}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE createBadgeForMedia --------------------------------"
        )
        print(f"Error: {str(e)}")
        return {"status": "error", "message": str(e)}


async def postMediaBadgeEarned(uid: str, media_id: str, name: str, image_url: str):
    """
    Creates a badge for a specific media and posts that the user earned it

    Returns a dictionary with the status of the operation and any relevant messages.
    """
    try:
        if await checkMediaBadgeExists(media_id) == False:
            await createBadgeForMedia(media_id, name, image_url)
            print("Badge didn't exist, now it's created")
        else:
            print("Badge already existed")

        # Get the bid of the target badge
        response = (
            supabase.table("badges").select("bid").eq("media_id", media_id).execute()
        )
        if response.data and len(response.data) > 0:
            print("Supabase select for badge returned: ", response.data)
            bid = response.data[0]["bid"]
            badgeEarned = {"uid": uid, "bid": bid, "earned_at": "now()"}
            print("requesting badge posting")
            return postNewBadgeEarned(badgeEarned)
        else:
            return {
                "status": "error",
                "message": f"Badge creation succeeded but could not find badge for media_id {media_id}",
            }

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postMediaBadgeEarned --------------------------------"
        )
        print(f"Error: {str(e)}")
        return {"status": "error", "message": str(e)}


async def getBadgeWithMediaId(media_id: str):
    """
    Gets the badge associated with a specific media id

    Returns a dictionary with the badge information or an error message if there was an error.
    """
    try:
        response = (
            supabase.table("badges").select("*").eq("media_id", media_id).execute()
        )

        if response.data and len(response.data) > 0:
            print(
                f"------------------ getBadgeWithMediaId: Found badge for media_id {media_id}: {response.data[0]} ------------------"
            )
            return response.data[0]
        else:
            return {
                "status": "error",
                "message": f"No badge found for media_id: {media_id}",
            }

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgeWithMediaId --------------------------------"
        )
        print(f"Error: {str(e)}")
        return {"status": "error", "message": str(e)}


async def getBadgesEarnedInYear(uid: str, year: str):
    """
    Gets all badges earned by a specific person in a specific year from the database

    Returns a list of tuples with badge earned at 0 and the badge at 1 or an error message if there was an error.
    """
    try:
        response = (
            supabase.table("badges_earned")
            .select("*")
            .eq("uid", uid)
            .gte(
                "earned_at", f"{year}-01-01"
            )  # greater than or equal to January 1st of the year
            .lte("earned_at", f"{year}-12-31")  # less than
            .execute()
        )

        badges = []

        for badge_earned in response.data:
            badge = getBadgeFromId(badge_earned["bid"])
            badges.append(badge[0])

        return badges

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE getBadgesEarnedInYear --------------------------------"
        )
        return {"status": "error", "message": str(e)}
