import os
import json
from PIL import Image
from tqdm import tqdm
import numpy as np
import torch
from transformers import CLIPProcessor, CLIPModel

# Config
CANONICAL_DIR = "canonical"    # structure: canonical/<item_id>/*.jpg
OUTPUT_DIR = "index"           # will contain embeddings.npz and metadata.json
MODEL_NAME = "openai/clip-vit-base-patch32"  #
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Load CLIP
model = CLIPModel.from_pretrained(MODEL_NAME).to(DEVICE)
processor = CLIPProcessor.from_pretrained(MODEL_NAME)

embeddings = []    # list of embedding vectors (float32)
metadatas = []     # list of dicts: {item_id, filename}

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
    
def image_paths_for_item(item_dir):
    exts = (".jpg", ".jpeg", ".png", ".webp")
    return [os.path.join(item_dir, f) for f in os.listdir(item_dir) if f.lower().endswith(exts)]

# Iterate items
for item_id in sorted(os.listdir(CANONICAL_DIR)):
    item_dir = os.path.join(CANONICAL_DIR, item_id)
    if not os.path.isdir(item_dir):
        continue
    paths = image_paths_for_item(item_dir)
    if not paths:
        continue
    for p in tqdm(paths, desc=f"Processing {item_id}"):
        image = Image.open(p).convert("RGB")
        inputs = processor(images=image, return_tensors="pt").to(DEVICE)
        with torch.no_grad():
            emb = get_image_embedding_from_processor(model, processor, image)
        embeddings.append(emb)
        metadatas.append({"item_id": item_id, "filename": os.path.relpath(p)})

# Save to disk
emb_array = np.vstack(embeddings)
np.savez_compressed(os.path.join(OUTPUT_DIR, "embeddings.npz"), embeddings=emb_array)
with open(os.path.join(OUTPUT_DIR, "metadata.json"), "w") as f:
    json.dump(metadatas, f, indent=2)

print("Saved embeddings:", os.path.join(OUTPUT_DIR, "embeddings.npz"))
print("Saved metadata:", os.path.join(OUTPUT_DIR, "metadata.json"))
