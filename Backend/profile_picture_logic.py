import os
import uuid
from typing import Optional
import boto3
from botocore.exceptions import ClientError
from pydantic import BaseModel
from fastapi import HTTPException

LOGLEVEL = 2
# if (LOGLEVEL>n):
#    print("")


AWS_REGION = os.getenv("AWS_REGION", "us-west-2")
BUCKET = os.getenv("S3_BUCKET", "popmedia-profile-pictures-us-west-2")
CLOUDFRONT_DOMAIN = os.getenv("CLOUDFRONT_DOMAIN", "")  # optional
MAX_BYTES = int(os.getenv("MAX_UPLOAD_BYTES", 5 * 1024 * 1024))  # 5 MB default
ALLOWED_EXT = {"jpg", "jpeg", "png", "webp"}


# boto3 S3 client (will use env AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY or instance role)
s3 = boto3.client("s3", region_name=AWS_REGION)


class SignRequest(BaseModel):
    filename: str
    method: Optional[str] = "put"  # "put" or "post"
    pictureType: Optional[str] = "profile"


def _allowed_extension(filename: str) -> bool:
    if "." not in filename:
        return False
    ext = filename.rsplit(".", 1)[-1].lower()
    return ext in ALLOWED_EXT


def _make_object_key(user_id: str, filename: str) -> str:
    ext = filename.rsplit(".", 1)[-1].lower()
    return f"users/{user_id}/profile/{uuid.uuid4().hex}.{ext}"


def _make_playlist_cover_key(user_id: str, filename: str) -> str:
    ext = filename.rsplit(".", 1)[-1].lower()
    return f"users/{user_id}/playlist/{uuid.uuid4().hex}.{ext}"


def sign_upload(user_id, req):
    if not _allowed_extension(req.filename):
        raise HTTPException(status_code=400, detail="File extension not allowed")
    # DEBUG
    if LOGLEVEL > 1:
        print("signing upload: file extension accepted")

    if req.pictureType == "profile":
        object_key = _make_object_key(user_id, req.filename)
    else:
        object_key = _make_playlist_cover_key(user_id, req.filename)
    ext = req.filename.rsplit(".", 1)[-1].lower()
    content_type = f"image/{'jpeg' if ext in ['jpg', 'jpeg'] else ext}"

    # DEBUG
    if LOGLEVEL > 1:
        print("signing upload: object key made")

    if req.method and req.method.lower() == "post":
        # DEBUG
        if LOGLEVEL > 1:
            print("signing upload: user wants to post")
        # presigned POST allows server-side policy constraints (content-length-range)
        conditions = [
            ["content-length-range", 0, MAX_BYTES],
            {"Content-Type": content_type},
        ]
        fields = {"Content-Type": content_type, "key": object_key}
        presigned_post = s3.generate_presigned_post(
            Bucket=BUCKET,
            Key=object_key,
            Fields=fields,
            Conditions=conditions,
            ExpiresIn=900,  # seconds
        )
        return {
            "method": "post",
            "uploadData": presigned_post,
            "objectKey": object_key,
            "cdnUrl": (
                f"https://{CLOUDFRONT_DOMAIN}/{object_key}"
                if CLOUDFRONT_DOMAIN
                else None
            ),
        }
    else:
        # DEBUG
        if LOGLEVEL > 1:
            print("signing upload: user wants to put")
        params = {"Bucket": BUCKET, "Key": object_key, "ContentType": content_type}
        # DEBUG
        if LOGLEVEL > 1:
            print("signing upload: params:", params)
        # presigned PUT (client PUTs the file bytes to the URL). Content-length can't be enforced by S3 here.
        presigned_put = s3.generate_presigned_url(
            "put_object", Params=params, ExpiresIn=900
        )

        return {
            "method": "put",
            "uploadUrl": presigned_put,
            "objectKey": object_key,
            "cdnUrl": (
                f"https://{CLOUDFRONT_DOMAIN}/{object_key}"
                if CLOUDFRONT_DOMAIN
                else None
            ),
        }


def confirm_upload(user_id: str, payload: dict):
    object_key = payload.get("objectKey")
    if not object_key:
        raise HTTPException(status_code=400, detail="Missing objectKey")

    # ensure the key belongs to this user
    expected_prefix = f"users/{user_id}/"
    if not object_key.startswith(expected_prefix):
        raise HTTPException(status_code=403, detail="Object key mismatch")

    try:
        head = s3.head_object(Bucket=BUCKET, Key=object_key)
    except ClientError as e:
        # 404 or other error from S3
        print("S3 head_object failed for %s", object_key)
        raise HTTPException(
            status_code=400, detail=f"Uploaded object not found: {str(e)}"
        )

    # server-side checks
    content_length = head.get("ContentLength", 0)
    content_type = head.get("ContentType", "")
    if content_length > MAX_BYTES:
        # optionally delete oversized object
        print("Uploaded object too large: %s (%d bytes)", object_key, content_length)
        # s3.delete_object(Bucket=BUCKET, Key=object_key)   # optional cleanup
        raise HTTPException(status_code=400, detail="Uploaded file is too large")

    # ensure content-type is accepted (defensive)
    if not any(
        content_type.startswith(t) for t in ("image/jpeg", "image/png", "image/webp")
    ):
        print("Uploaded object wrong content type: %s (%s)", object_key, content_type)
        raise HTTPException(status_code=400, detail="Invalid content type")

    return True, object_key


def get_presigned_get(object_key, expires):

    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET, "Key": object_key},
            ExpiresIn=expires,
        )
        # DEBUG
        if LOGLEVEL > 1:
            print("get presigned get: url:", url)
        return {"url": url}
    except Exception as e:
        raise HTTPException(
            status_code=400, detail=f"Cannot create presigned URL: {str(e)}"
        )
