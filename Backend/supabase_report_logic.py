from supabase_connection_logic import supabase
from fastapi import HTTPException
import supabase_review_logic

def postReport(
    associated_id: str,
    type: str,
    reason: str,
    reporter: str,
    created_at: str,
    resolved: bool,
):
    """
    Adds a users report to the database in reports table

    Returns a dictionary saying whether or not it was a success or if there was an error and what the error is.
    """

    try:
        table = "reports"

        response = (
            supabase.table(table)
            .insert(
                {
                    "associated_id": associated_id,
                    "type": type,
                    "reason": reason,
                    "reporter": reporter,
                    "created_at": created_at,
                    "resolved": resolved,
                }
            )
            .execute()
        )

        return {"status": "success", "table": table}

    except Exception as e:
        print(
            "-------------------------------- CHECKPOINT FAILURE postReport --------------------------------"
        )
        return {"status": "error", "message": str(e)}


def resolveReport(issue_id: int, resolved: bool):
    try:
        supabase.table("reports").update({"resolved": resolved}).eq(
            "issue_id", issue_id
        ).execute()
        return {"status": "ok"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def getReport(resolved: bool) -> list:
    """
    Gets all unresolved / resolved reports from the database.

    Returns a list of report dictionaries.
    """
    try:
        table = "reports"

        response = supabase.table(table).select("*").eq("resolved", resolved).execute()

        return response.data or []

    except Exception as e:
        return {"status": "error", "message": str(e)}


async def getReviewMediaFromReport(associated_id: str) -> list:
    try:
        split_text = associated_id.split(",")
        media_type = split_text[0][0].lower()
        review_id = int(split_text[1])
        # print(f'--------- associated_id: {associated_id}, media_type: {media_type}, review_id: {review_id} ---------')
        if media_type == "m":
            table = "movie_reviews"
        elif media_type == "t":
            table = "television_reviews"
        else:
            table = "book_reviews"

        response = supabase.table(table).select("*").eq("id", review_id).execute()

        review = response.data[0]
        cleaned_review = await supabase_review_logic.cleanSupabaseReview(review)
        media_review = await supabase_review_logic.matchReviewToMedia(review)

        result = [media_type, cleaned_review, media_review[1]]

        return result

    except Exception as e:
        print("===========================================")
        print(f"Error getting season review for review_id {review_id}, error: {e}")
        print("===========================================")
        return {"status": "error", "message": str(e)}