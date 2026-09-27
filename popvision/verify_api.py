from contextlib import asynccontextmanager
import importlib
import os
import tempfile
from typing import Any

import requests
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import base64

from PIL import Image
from io import BytesIO

_verify_module = None

controllerURL="https://api.thepopmedia.com"
class VerifyRequest(BaseModel):
    canonical_image_url: str = Field(..., min_length=1)
    user_image_base64: str = Field(..., min_length=1)
    metadata: dict[str, Any]
    uid: str
    stillUploading: bool


@asynccontextmanager
async def lifespan(app: FastAPI):
    verify_module = get_verify_module()
    verify_module.initialize_service()
    yield


app = FastAPI(title="Image Verification API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_verify_module():
    global _verify_module
    if _verify_module is None:
        _verify_module = importlib.import_module("verify")
    return _verify_module


def _download_image_to_temp(url: str) -> str:
    response = requests.get(url, timeout=20)
    response.raise_for_status()
    content_type = response.headers.get("content-type", "").lower()
    if not content_type.startswith("image/"):
        raise ValueError(f"URL does not point to an image: {content_type}")
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(response.content)
        tmp.flush()
        return tmp.name

def _parse_base64_image_to_temp(base64_image: str) -> str:
    base64_image = base64_image.split("base64,", 1)[1] if "base64," in base64_image else base64_image
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(base64.b64decode(base64_image, validate=True))
        tmp.flush()
        return tmp.name

@app.post("/verifyImageMatch")
async def verify_image_match(req: VerifyRequest):
    print("DEBUG: req.canonical_image_url", req.canonical_image_url)
    print("DEBUG: req.metadata", req.metadata)
    print("DEBUG: req.user_image_base64", req.user_image_base64[0:64])
    verify_module = get_verify_module()
    media_id = req.metadata.get("id")
    if not media_id:
        raise HTTPException(status_code=422, detail="metadata.media_id is required")
    
    cover_text = None
    try:
        cover_text = verify_module.ensure_item_in_index(
            item_id=media_id,
            canonical_image_url=req.canonical_image_url,
            metadata=req.metadata,
        )
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Failed to ensure canonical index: {exc}") from exc

    user_tmp = None
    try:
        user_tmp = _parse_base64_image_to_temp(req.user_image_base64)
        result = verify_module.verify(photo_path=user_tmp, metadata=req.metadata, cover_text=cover_text)
        output = {
            "media_id": str(media_id),
            "confidence": result.get("composite_score", 0.0),
            "accepted": result.get("accepted", False),
            "reason": result.get("reason"),
            "best_sim": result.get("best_sim"),
            "ocr_score": result.get("ocr_score"),
            "inliers": result.get("inliers"),
            "composite_score": result.get("composite_score"),
            #"matched_canonical": result.get("matched_canonical"),
        }
        print(output)
        if output["accepted"]==True and req.stillUploading==False:
            requests.post(url=controllerURL+"/postMediaBadgeEarned", params={"media_id": media_id, "uid": req.uid, "name": req.metadata.get("name"), "image_url": req.canonical_image_url})
            return output
        return output
    except HTTPException:
        raise
    except Exception as exc:
        print(f"EXCEPTION: {exc}")
        raise HTTPException(status_code=500, detail=f"Verification failed: {exc}") from exc
    finally:
        if user_tmp and os.path.exists(user_tmp):
            os.remove(user_tmp)
