"""
Lexica Spire - Map Icon Generator with transparent backgrounds.
Generates icons via OpenRouter API, then removes background with rembg.
"""

import requests
import base64
import os
import time
import io

API_KEY = "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"
MODEL = "nanobanana/nanobanana"
FALLBACK_MODEL = "google/gemini-2.5-flash-image"
BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

OUTPUT_DIR = "e:/github/slay_the_spire/godot/assets/sprites/ui"

BASE_STYLE = (
    "A single iconic symbol/icon for a dark fantasy card game map. "
    "Painted in a dark, moody oil-painting style with visible brushstrokes. "
    "The icon is centered, highly detailed, glowing with magical energy. "
    "CRITICAL: The object must be on a SOLID PURE BLACK (#000000) background. "
    "No ground, no environment, no other objects — just the icon floating on pure black. "
    "No text, no letters, no words, no numbers, no watermarks. "
    "The icon should be clearly readable at 80x80 pixels. "
)

ICONS = [
    {
        "id": "icon_combat",
        "prompt": BASE_STYLE +
            "Two crossed medieval swords with ornate hilts, metallic steel blades "
            "with a subtle crimson red glow along the edges. Dark fantasy weapon icon. "
            "Dramatic rim lighting on the blades.",
        "path": "icon_combat.png",
    },
    {
        "id": "icon_elite",
        "prompt": BASE_STYLE +
            "A menacing horned demon skull with curved horns, dark crimson red glowing eyes. "
            "Cracked bone texture, ancient and terrifying. Elite enemy symbol. "
            "Faint red aura emanating from the skull.",
        "path": "icon_elite.png",
    },
    {
        "id": "icon_library",
        "prompt": BASE_STYLE +
            "An open ancient magical book with glowing blue pages, arcane symbols floating "
            "above the pages. Golden binding and clasps. Knowledge and wisdom symbol. "
            "Soft blue light emanating from the pages.",
        "path": "icon_library.png",
    },
    {
        "id": "icon_rest",
        "prompt": BASE_STYLE +
            "A warm campfire with three dancing flames, orange and golden fire. "
            "Small logs beneath. Warm, inviting, peaceful rest symbol. "
            "Warm orange glow radiating outward.",
        "path": "icon_rest.png",
    },
    {
        "id": "icon_shop",
        "prompt": BASE_STYLE +
            "A leather coin purse overflowing with golden coins, some coins falling out. "
            "Rich golden glow from the coins. Commerce and trade symbol. "
            "Shiny metallic gold highlights.",
        "path": "icon_shop.png",
    },
    {
        "id": "icon_event",
        "prompt": BASE_STYLE +
            "A glowing mystical question mark symbol made of swirling purple arcane energy, "
            "floating in space. Mysterious, magical, unknown event. "
            "Purple and violet magical particles around it.",
        "path": "icon_event.png",
    },
    {
        "id": "icon_boss",
        "prompt": BASE_STYLE +
            "A dark spiked crown with a blood-red gemstone in the center. "
            "Golden metal with dark spikes, imposing and regal. Boss/king symbol. "
            "Golden glow from the crown, red glow from the gem. Slightly larger and more ornate.",
        "path": "icon_boss.png",
    },
]


def generate_image(icon_def, model):
    """Call OpenRouter API to generate an image."""
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/lexica-spire",
        "X-Title": "Lexica Spire Icon Generator",
    }

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"Generate an image. Return ONLY the image, no text.\n\n{icon_def['prompt']}",
                    }
                ],
            }
        ],
        "max_tokens": 4096,
    }

    try:
        resp = requests.post(BASE_URL, headers=headers, json=payload, timeout=120)
        resp.raise_for_status()
        data = resp.json()

        choices = data.get("choices", [])
        if not choices:
            print(f"  [WARN] No choices for {icon_def['id']}")
            return None

        message = choices[0].get("message", {})

        # Check images[] array
        images = message.get("images", [])
        if images:
            for img in images:
                if isinstance(img, dict):
                    url_data = img.get("image_url", {}).get("url", "")
                    if url_data.startswith("data:"):
                        b64 = url_data.split(",", 1)[1]
                        return base64.b64decode(b64)

        # Fallback: check content parts
        content = message.get("content", "")
        if isinstance(content, list):
            for part in content:
                if isinstance(part, dict):
                    if "inline_data" in part:
                        b64 = part["inline_data"].get("data", "")
                        if b64:
                            return base64.b64decode(b64)
                    if part.get("type") == "image_url":
                        url_data = part.get("image_url", {}).get("url", "")
                        if url_data.startswith("data:"):
                            b64 = url_data.split(",", 1)[1]
                            return base64.b64decode(b64)

        print(f"  [WARN] No image in response for {icon_def['id']}")
        if isinstance(content, str) and content:
            print(f"  Text: {content[:200]}")
        return None

    except requests.exceptions.HTTPError as e:
        print(f"  [ERROR] HTTP {e.response.status_code}: {e.response.text[:300]}")
        return None
    except Exception as e:
        print(f"  [ERROR] {type(e).__name__}: {e}")
        return None


def remove_background(image_bytes):
    """Remove background using rembg, return PNG with transparency."""
    from rembg import remove
    from PIL import Image

    input_image = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    output_image = remove(input_image)

    # Resize to 96x96 for map nodes (boss is 96x96, regular 80x80 but we'll use same size)
    output_image = output_image.resize((96, 96), Image.LANCZOS)

    buf = io.BytesIO()
    output_image.save(buf, format="PNG")
    return buf.getvalue()


def main():
    print("=" * 50)
    print("  MAP ICON GENERATOR (transparent background)")
    print("=" * 50)

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    success = 0
    failed = []
    model = MODEL

    for i, icon in enumerate(ICONS, 1):
        print(f"\n[{i}/{len(ICONS)}] Generating: {icon['id']}...")

        image_data = generate_image(icon, model)

        # If primary model fails, try fallback
        if image_data is None and model != FALLBACK_MODEL:
            print(f"  Trying fallback model: {FALLBACK_MODEL}")
            model = FALLBACK_MODEL
            image_data = generate_image(icon, model)

        if image_data:
            print(f"  Removing background...")
            try:
                transparent_data = remove_background(image_data)
                path = os.path.join(OUTPUT_DIR, icon["path"])
                with open(path, "wb") as f:
                    f.write(transparent_data)
                print(f"  [OK] Saved: {path} ({len(transparent_data)} bytes)")
                success += 1
            except Exception as e:
                print(f"  [ERROR] Background removal failed: {e}")
                failed.append(icon["id"])
        else:
            failed.append(icon["id"])

        if i < len(ICONS):
            time.sleep(2)

    print(f"\n{'=' * 50}")
    print(f"  DONE: {success}/{len(ICONS)} icons generated")
    if failed:
        print(f"  FAILED: {', '.join(failed)}")
    print("=" * 50)


if __name__ == "__main__":
    main()
