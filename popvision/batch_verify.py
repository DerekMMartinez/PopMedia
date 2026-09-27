import os
import argparse
import csv
import traceback
import importlib

def collect_images(folder):
    exts = (".jpg", ".jpeg", ".png", ".webp")
    images = []
    for root, _, files in os.walk(folder):
        for f in files:
            if f.lower().endswith(exts):
                images.append(os.path.join(root, f))
    images.sort()
    return images

def safe_verify_call(verify_fn, photo_path, item_id):
    try:
        out = verify_fn(photo_path, item_id)
        # ensure we return a dictionary with expected keys
        return {
            "matched_canonical": out.get("matched_canonical"),
            "photo": photo_path,
            "accepted": bool(out.get("accepted", False)),
            "best_sim": out.get("best_sim"),
            "reason": out.get("reason"),
            "inliers": out.get("inliers"),
            "composite_score": out.get("composite_score"),
            "error": ""
        }
    except Exception as e:
        return {
            "photo": photo_path,
            "accepted": False,
            "best_sim": None,
            "matched_canonical": None,
            "reason": "error",
            "inliers": None,
            "composite_score": None,
            "error": f"{type(e).__name__}: {str(e)}\n{traceback.format_exc()}"
        }

def main():
    parser = argparse.ArgumentParser(description="Batch-run verify() from verify.py on a folder of images")
    parser.add_argument("--item_id", required=True, help="Target item_id")
    parser.add_argument("--pos_dir", help="Folder with positive images (matching the item)")
    parser.add_argument("--neg_dir", help="Optional folder with negative images")
    parser.add_argument("--out_csv", default="batch_verify_results.csv")
    args = parser.parse_args()
    
    verify_mod = importlib.import_module("verify")  # assumes verify.py is in same folder / python path
    if not hasattr(verify_mod, "verify"):
        raise RuntimeError("verify.py does not expose a `verify(photo_path, item_id)` function.")

    rows = []
    true_labels = {}

    if args.pos_dir:
        pos_imgs = collect_images(args.pos_dir)
        for p in pos_imgs:
            rows.append((p, 1))
    if args.neg_dir:
        neg_imgs = collect_images(args.neg_dir)
        for p in neg_imgs:
            rows.append((p, 0))

    if not rows:
        print("No images found. Provide --pos_dir and/or --neg_dir.")
        return

    # Run verification for each image
    results = []
    for i, (photo_path, label) in enumerate(rows, start=1):
        print(f"[{i}/{len(rows)}] Verifying: {photo_path} (true={label})")
        res = safe_verify_call(verify_mod.verify, photo_path, args.item_id)
        res["true_label"] = int(label)

        results.append(res)

    # Save CSV
    fieldnames = ["matched_canonical", "photo", "true_label", "accepted", "best_sim", "inliers", "composite_score","reason", "error"]
    with open(args.out_csv, "w", newline="", encoding="utf-8") as cf:
        writer = csv.DictWriter(cf, fieldnames=fieldnames)
        writer.writeheader()
        for r in results:
            writer.writerow({
                "matched_canonical": r.get("matched_canonical"),
                "photo": r.get("photo"),
                "true_label": r.get("true_label"),
                "accepted": int(bool(r.get("accepted"))),
                "best_sim": r.get("best_sim"),
                "inliers": r.get("inliers"),
                "composite_score": r.get("composite_score"),
                "reason": r.get("reason"),
                "error": (r.get("error") or "")
            })
    
    TP = FP = TN = FN = 0
    for r in results:
        accepted = bool(r.get("accepted"))
        y = int(r.get("true_label", 0))
        if y == 1 and accepted:
            TP += 1
        if y == 1 and not accepted:
            FN += 1
        if y == 0 and accepted:
            FP += 1
        if y == 0 and not accepted:
            TN += 1

    total = len(results)
    print("\n=== Summary ===")
    print(f"Evaluated: {total}   (pos={sum(1 for _,l in rows if l==1)}, neg={sum(1 for _,l in rows if l==0)})")
    print(f"TP={TP} FP={FP} TN={TN} FN={FN}")
    precision = TP / (TP + FP) if (TP + FP) > 0 else 0.0
    recall = TP / (TP + FN) if (TP + FN) > 0 else 0.0
    accuracy = (TP + TN) / total if total > 0 else 0.0
    print(f"Precision={precision:.4f}  Recall={recall:.4f}  Accuracy={accuracy:.4f}")
    print(f"CSV saved to: {args.out_csv}")

    
if __name__ == "__main__":
    main()