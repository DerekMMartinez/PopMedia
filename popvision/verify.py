import argparse
import json
import numpy as np
from PIL import Image
import torch
from transformers import CLIPProcessor, CLIPModel
import os
import cv2
import re
from rapidfuzz import fuzz
import tempfile
import threading
import uuid
from pathlib import Path
import requests

_ocr_lock = threading.Lock()
_paddle_ocr = None


def _get_paddle_ocr():
    global _paddle_ocr
    with _ocr_lock:
        if _paddle_ocr is None:
            os.environ.setdefault("PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK", "True")
            from paddleocr import PaddleOCR

            _paddle_ocr = PaddleOCR(
                lang="en",
                use_doc_orientation_classify=False,
                use_doc_unwarping=False,
                use_textline_orientation=True,
            )
        return _paddle_ocr


def _texts_from_paddle_results(results):
    lines = []
    for item in results or []:
        if isinstance(item, dict) and item.get("error"):
            continue
        try:
            rec_texts = item["rec_texts"]
        except (TypeError, KeyError):
            continue
        for t in rec_texts:
            if t:
                lines.append(str(t))
    return lines


def extract_ocr_text(image_path):
    try:
        ocr = _get_paddle_ocr()
        path = str(Path(image_path).resolve())
        raw = ocr.predict(
            path,
            use_doc_orientation_classify=False,
            use_doc_unwarping=False,
            use_textline_orientation=True,
        )
        text = " ".join(_texts_from_paddle_results(raw))
        text = text.lower()
        text = re.sub(r"[^a-z0-9\s]", " ", text)
        text = re.sub(r"\s+", " ", text).strip()
        return text
    except Exception as e:
        print("OCR failed:", e)
        return ""


def ocr_match_score(ocr_text, target_text):
    """
    Returns a score 0–100
    """
    if not ocr_text or not target_text:
        return 0

    target_text = target_text.lower()

    # partial_ratio works well for substrings
    score = fuzz.partial_ratio(ocr_text, target_text)
    return score
# Config
MODEL_NAME = "openai/clip-vit-base-patch32"
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
BASE_DIR = Path(__file__).resolve().parent
INDEX_DIR = BASE_DIR / "index"
CANONICAL_DIR = BASE_DIR / "canonical"

# Thresholds
SIMILARITY_ACCEPT_THRESHOLD = 0.77  
SIMILARITY_BORDERLINE = 0.0        # if between borderline and accept, run geometric check
INLIER_THRESHOLD = 225               # number of RANSAC inliers to accept
INLIER_BASE = 170

_state_lock = threading.RLock()
embs = np.empty((0, 512), dtype=np.float32)
metas = []
item_to_rows = {}
model = None
processor = None
_initialized = False


def _rebuild_item_to_rows():
    global item_to_rows
    item_to_rows = {}
    for idx, m in enumerate(metas):
        item_to_rows.setdefault(str(m["item_id"]), []).append(idx)


def _load_index():
    global embs, metas
    embeddings_path = INDEX_DIR / "embeddings.npz"
    metadata_path = INDEX_DIR / "metadata.json"
    INDEX_DIR.mkdir(parents=True, exist_ok=True)

    if embeddings_path.exists() and metadata_path.exists():
        data = np.load(str(embeddings_path))
        embs = data["embeddings"].astype(np.float32)
        with open(metadata_path, "r", encoding="utf-8") as f:
            metas = json.load(f)
    else:
        embs = np.empty((0, 512), dtype=np.float32)
        metas = []
    _rebuild_item_to_rows()


def initialize_service():
    global model, processor, _initialized
    with _state_lock:
        if _initialized:
            return
        hf_token = os.getenv("HF_TOKEN") or os.getenv("HUGGINGFACE_HUB_TOKEN")
        if hf_token:
            model = CLIPModel.from_pretrained(MODEL_NAME, token=hf_token).to(DEVICE)
        else:
            model = CLIPModel.from_pretrained(MODEL_NAME).to(DEVICE)
        processor = CLIPProcessor.from_pretrained(MODEL_NAME)
        _load_index()
        _initialized = True
        print("############## Initialized Successfully ####################")


def _persist_index():
    embeddings_tmp = INDEX_DIR / "embeddings.tmp.npz"
    metadata_tmp = INDEX_DIR / "metadata.tmp.json"
    embeddings_path = INDEX_DIR / "embeddings.npz"
    metadata_path = INDEX_DIR / "metadata.json"

    np.savez_compressed(str(embeddings_tmp), embeddings=embs)
    with open(metadata_tmp, "w", encoding="utf-8") as f:
        json.dump(metas, f, indent=2)
    os.replace(embeddings_tmp, embeddings_path)
    os.replace(metadata_tmp, metadata_path)


def _download_url_to_temp_file(url):
    response = requests.get(url, timeout=20)
    response.raise_for_status()
    content_type = response.headers.get("content-type", "").lower()
    if not content_type.startswith("image/"):
        raise ValueError(f"URL does not point to an image: {content_type}")
    suffix = ".jpg"
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    try:
        tmp.write(response.content)
        tmp.flush()
        return tmp.name
    finally:
        tmp.close()


def _copy_canonical_to_store(item_id, source_file):
    target_dir = CANONICAL_DIR / str(item_id)
    target_dir.mkdir(parents=True, exist_ok=True)
    target_path = target_dir / f"{uuid.uuid4().hex}.jpg"
    image = Image.open(source_file).convert("RGB")
    image.save(target_path, format="JPEG")
    return str(target_path)


def ensure_item_in_index(item_id, canonical_image_url, metadata=None):
    """
    Add canonical image to index if item_id does not exist.
    Returns the text on the canonical image.
    """
    initialize_service()
    item_id = str(item_id)
    with _state_lock:
        if item_id in item_to_rows:
            return False

    tmp_path = None
    try:
        tmp_path = _download_url_to_temp_file(canonical_image_url)
        emb = get_image_embedding_from_processor(model, processor, tmp_path)
        canonical_path = _copy_canonical_to_store(item_id, tmp_path)
        meta_record = {"item_id": item_id, "filename": canonical_path}
        if metadata and isinstance(metadata, dict):
            meta_record["request_metadata"] = metadata

        cover_text = extract_ocr_text(tmp_path)
        with _state_lock:
            global embs
            if embs.size == 0:
                embs = emb.reshape(1, -1)
            else:
                embs = np.vstack([embs, emb.astype(np.float32)])
            metas.append(meta_record)
            _rebuild_item_to_rows()
            _persist_index()
        return True
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)

def get_image_embedding_from_processor(model, processor, image):
    """
    Returns a 1-D numpy float32 L2-normalized embedding (shape (D,))
    Robust across transformers versions where get_image_features may return:
      - torch.Tensor
      - BaseModelOutputWithPooling with .image_embeds
      - BaseModelOutputWithPooling with .pooler_output
      - BaseModelOutputWithPooling with .last_hidden_state (we mean-pool)
    """
    if isinstance(image, str):
        image = Image.open(image).convert("RGB")

    # prepare inputs and send to same device as model
    inputs = processor(images=image, return_tensors="pt").to(next(model.parameters()).device)

    with torch.no_grad():
        # try to use get_image_features if present
        if hasattr(model, "get_image_features"):
            out = model.get_image_features(**inputs)
        else:
            # fallback: run vision_model (for CLIPVisionModel or older versions)
            # some models expose .vision_model which returns a model output wrapper
            if hasattr(model, "vision_model"):
                out = model.vision_model(**inputs)
            else:
                # last resort: call model(**inputs) — but DO NOT do this for multimodal CLIPModel
                out = model(**inputs)

        # out might be:
        #  - a torch.Tensor (the embedding)
        #  - an object with attributes: image_embeds, pooler_output, last_hidden_state
        img_emb = None
        if isinstance(out, torch.Tensor):
            img_emb = out
        elif hasattr(out, "image_embeds"):
            img_emb = out.image_embeds
        elif hasattr(out, "pooler_output"):
            img_emb = out.pooler_output
        elif hasattr(out, "last_hidden_state"):
            # mean-pool last_hidden_state over sequence dim (1) to get a pooled vector
            l = out.last_hidden_state
            if isinstance(l, torch.Tensor) and l.dim() >= 2:
                img_emb = l.mean(dim=1)
        else:
            # nothing matched — dump debug info to help diagnose
            raise RuntimeError(
                "Couldn't extract image features from model output. Output type: %s; "
                "dir(output) sample: %s" % (type(out), [a for a in dir(out) if not a.startswith('_')][:20])
            )

        # At this point img_emb should be a torch.Tensor of shape (1, D) or (D,)
        if not isinstance(img_emb, torch.Tensor):
            raise RuntimeError("Unexpected image embedding type after extraction: %s" % type(img_emb))

        # Ensure shape is (1, D)
        if img_emb.dim() == 1:
            img_emb = img_emb.unsqueeze(0)

        # Normalize
        img_emb = img_emb / torch.norm(img_emb, p=2, dim=-1, keepdim=True)

        emb = img_emb.squeeze(0).cpu().numpy().astype(np.float32)  # shape (D,)
        # sanity check
        if emb.ndim != 1 or emb.shape[0] <= 1:
            raise RuntimeError(f"Bad embedding shape after extraction: {emb.shape}")

        return emb

def embed_image(path):
    initialize_service()
    image = Image.open(path).convert("RGB")
    inputs = processor(images=image, return_tensors="pt").to(DEVICE)
    with torch.no_grad():
        return get_image_embedding_from_processor(model, processor, image)
    

def cosine(a, b):
    """
    a: (D,) numpy array-like
    b: (K, D) or (D,) numpy array-like
    returns: (K,) numpy array or scalar
    """
    a = np.asarray(a, dtype=np.float32).reshape(-1)
    b = np.asarray(b, dtype=np.float32)
    # fallback: if b is 1-D do scalar cos
    if b.ndim == 1:
        denom = (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12)
        return float(np.dot(a, b) / denom)
    # else b is (K, D)
    b_norms = np.linalg.norm(b, axis=1, keepdims=True) + 1e-12
    b_normed = b / b_norms
    a_norm = a / (np.linalg.norm(a) + 1e-12)
    sims = b_normed.dot(a_norm)   # shape (K,)
    return sims

# Optional geometric verification (ORB + homography)
def geometric_verify(user_img_path, canon_img_path):
    # returns number of inliers (int)
    u = cv2.imread(user_img_path, cv2.IMREAD_COLOR)
    c = cv2.imread(canon_img_path, cv2.IMREAD_COLOR)
    if u is None or c is None:
        return 0
    # convert to gray
    u_gray = cv2.cvtColor(u, cv2.COLOR_BGR2GRAY)
    c_gray = cv2.cvtColor(c, cv2.COLOR_BGR2GRAY)
    orb = cv2.ORB_create(2000)
    kp1, des1 = orb.detectAndCompute(u_gray, None)
    kp2, des2 = orb.detectAndCompute(c_gray, None)
    if des1 is None or des2 is None:
        return 0
    # BFMatcher with Hamming
    bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False)
    matches = bf.knnMatch(des1, des2, k=2)
    # ratio test
    good = []
    for m_n in matches:
        if len(m_n) < 2:
            continue
        m, n = m_n
        if m.distance < 0.75 * n.distance:
            good.append(m)
    if len(good) < 8:
        return 0
    src_pts = np.float32([kp1[m.queryIdx].pt for m in good]).reshape(-1, 1, 2)
    dst_pts = np.float32([kp2[m.trainIdx].pt for m in good]).reshape(-1, 1, 2)
    H, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)
    if mask is None:
        return 0
    inliers = int(mask.sum())
    return inliers

# show stats
def stats(x, name):
    x = np.asarray(x)
    print(f"  {name}: min={x.min():.6f} max={x.max():.6f} mean={x.mean():.6f} std={x.std():.6f}")


def verify(photo_path, metadata=None, cover_text=None):
    initialize_service()

    item_id = metadata.get("id")
    target_title = metadata.get(str(item_id), {}).get("name", "")
    if str(item_id) not in item_to_rows:
        print("No canonical images indexed for item:", item_id)
        return {"result": "no_canonical", "confidence": 0.0}
    user_emb = embed_image(photo_path)
    rows = item_to_rows[str(item_id)]
    item_embs = embs[rows]  # (K, D)

    # suppose user_emb and item_embs are available here//DEBUG---------------------------------------------
    print("DEBUG: user_emb dtype/shape:", getattr(user_emb, "dtype", None), np.shape(user_emb))
    print("DEBUG: item_embs dtype/shape:", getattr(item_embs, "dtype", None), np.shape(item_embs))

    stats(user_emb, "user_emb")
    # sample first 3 rows of item_embs
    for i in range(min(3, item_embs.shape[0])):
        stats(item_embs[i], f"item_embs[{i}]")

    # verify normalization
    norms_item = np.linalg.norm(item_embs, axis=1)
    print("  norms_item stats: min/max/mean:", norms_item.min(), norms_item.max(), norms_item.mean())
    print("  user_emb norm:", np.linalg.norm(user_emb))
    #//------------------------------------------------------------------DEBUG
    
    sims = cosine(user_emb, item_embs)  # (K,)
    sims = np.asarray(sims).reshape(-1)
    best_idx = int(np.argmax(sims))
    best_sim = float(sims[best_idx])
    best_row = rows[best_idx]
    best_meta = metas[best_row]

    ocr_text = extract_ocr_text(photo_path)

    ocr_score = ocr_match_score(ocr_text, target_title)

    cover_ocr_score = ocr_match_score(cover_text, target_title) if cover_text else 0.0

    if (cover_ocr_score > ocr_score):
        print("matched cover text instead of extracted OCR text due to higher score")
        ocr_score = cover_ocr_score
    print("DEBUG OCR:")
    print("  extracted:", ocr_text)
    print("  target:", target_title, "OR", cover_text if cover_text else "N/A")
    print("  score:", ocr_score)

    result = {"item_id": item_id,
              "best_sim": best_sim,
              "matched_canonical": best_meta["filename"],
              "accepted": False,
              "reason": None,
              "composite_score": 0.0}

    OCR_ACCEPT_THRESHOLD = 60
    OCR_STRONG_MATCH = 80

    result["ocr_score"] = ocr_score

    # Case 1: strong OCR match → trust it
    if ocr_score >= OCR_STRONG_MATCH and best_sim >= SIMILARITY_BORDERLINE:
        result["accepted"] = True
        result["reason"] = "ocr_strong_match"
        return result

    # Case 2: normal similarity + decent OCR
    if best_sim >= SIMILARITY_ACCEPT_THRESHOLD and ocr_score >= OCR_ACCEPT_THRESHOLD:
        result["accepted"] = True
        result["reason"] = "sim+ocr"
        return result

    #Case 2.5
    if (best_sim >= 0.84):
        result["accepted"] = True
        result["reason"] = "high_sim_no_ocr"
        return result
    # Case 3: fallback to your existing logic
    inliers = geometric_verify(photo_path, best_meta["filename"])
    result["inliers"] = inliers
    geom_rating= -1
    if (inliers> INLIER_BASE and inliers<INLIER_THRESHOLD):
        geom_rating = (2.0*(inliers - INLIER_BASE))/(INLIER_THRESHOLD - INLIER_BASE) -1
    elif (inliers>= INLIER_THRESHOLD):
        geom_rating = 1
    
    #geom_rating = (2.0 / (1.0 + np.exp(-(inliers - INLIER_THRESHOLD))))-1.0 
    #TODO: maybe get rid of the 0.7, does it matter if it is ranged differently?
    composite_score = (float)(best_sim + 0.2 * geom_rating) # simple weighted combo
    result["composite_score"] = composite_score
    if composite_score >= SIMILARITY_ACCEPT_THRESHOLD:
        result["accepted"] = True
        result["reason"] = "sim+geom"
    else:
        result["accepted"] = False
        result["reason"] = "similarity_low"
    return result
    # if best_sim >= SIMILARITY_ACCEPT_THRESHOLD:
    #     result["accepted"] = True
    #     result["reason"] = "similarity_high"
    #     return result
    # if best_sim >= SIMILARITY_ACCEPT_THRESHOLD:
    #     result["accepted"] = True
    #     result["reason"] = "similarity_high"
    #     return result

    # if best_sim >= SIMILARITY_BORDERLINE:
    #     # do geometric verification between photo and matched canonical image
    #     canon_path = best_meta["filename"]
    #     inliers = geometric_verify(photo_path, canon_path)
    #     result["inliers"] = inliers
    #     if inliers >= INLIER_THRESHOLD:
    #         result["accepted"] = True
    #         result["reason"] = "geom_verified"
    #     else:
    #         result["accepted"] = False
    #         result["reason"] = "geom_failed"
    #     return result

    # below borderline -> reject
    # result["accepted"] = False
    # result["reason"] = "similarity_low"
    # return result

if __name__ == "__main__":
    initialize_service()
    parser = argparse.ArgumentParser()
    parser.add_argument("--photo", required=True)
    parser.add_argument("--item_id", required=True)
    args = parser.parse_args()
    out = verify(args.photo, args.item_id)
    print(json.dumps(out, indent=2))
