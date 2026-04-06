"""
Lexica Spire - Asset Generator via OpenRouter (Gemini 2.5 Flash Image)
Generates all game art assets in a consistent dark fantasy style.
"""

import requests
import base64
import os
import time
import json
import sys

API_KEY = "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"
MODEL = "google/gemini-2.5-flash-image"
BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

GODOT_ASSETS = "e:/github/slay_the_spire/godot/assets"

# Base style prompt
BASE_STYLE = (
    "High-quality digital illustration for a fantasy deck-building card game, "
    "central composition focusing on {object}. "
    "Style is dark and moody stylized fantasy art with visible, textured oil brushstrokes "
    "and cross-hatching, reminiscent of traditional dark fantasy graphic novels. "
    "Heavy use of chiaroscuro lighting: strong contrast between deep shadows and dramatic, "
    "rim lighting highlighting edges. The color palette is restricted to desaturated, earthy tones "
    "(sepia, deep greys, burnt umber) with a single, vibrant accent color ({accent_color}) "
    "associated with the magical element. The background is atmospheric, vignette-style, "
    "blurry and dark, with subtle, carved runic stone textures barely visible. "
    "{extra} "
    "Clean and iconic look, sharp focus, highly detailed yet readable at small size. "
    "No text, no letters, no words, no numbers, no watermarks."
)

# ============================================================
# ASSET DEFINITIONS
# ============================================================

ENEMIES = [
    {
        "id": "whisper",
        "object": "a small wisp of black smoke floating low above the ground, "
                  "barely visible ghostly claws emerging from dark vapor, "
                  "faint skeletal fingers materialize, flickering unstable shard of a dark spirit",
        "accent_color": "faint eerie sickly green glow within the smoke",
        "extra": "Small spirit creature, front-facing portrait, dark fantasy horror, "
                 "bold rough black ink outlines, cross-hatching shadows, cel-shaded flat colors, "
                 "desaturated muted palette, grunge textures, solid bright lime green background #7FFF00",
        "path": "sprites/enemies/whisper.png",
    },
    {
        "id": "utgallu",
        "object": "a menacing dark spirit, large floating mass of black churning smoke wearing a hood "
                  "of intangible ethereal fabric, faint skeletal frame barely visible inside, "
                  "two long clawed hands materialize from the dark mass with sharp talons, "
                  "hollow darkness where the face should be, ancient mesopotamian occult aesthetic",
        "accent_color": "faint purple glow from within the hood",
        "extra": "Medium spirit creature, front-facing portrait, dark fantasy horror, "
                 "bold rough black ink outlines, cross-hatching shadows, cel-shaded flat colors, "
                 "desaturated muted palette, grunge textures, solid bright lime green background #7FFF00",
        "path": "sprites/enemies/utgallu.png",
    },
    {
        "id": "possessed_slave",
        "object": "a possessed emaciated slave, ancient Mesopotamian setting, "
                  "thin malnourished body with arms twisted at unnatural angles, "
                  "pure black eyes with dark pulsating veins spreading across the face, "
                  "mouth open mumbling, tattered loincloth, jerky contorted posture, body horror",
        "accent_color": "dark pulsating veins, sickly skin tones",
        "extra": "Possessed human enemy, front-facing portrait, dark fantasy horror, "
                 "bold rough black ink outlines, cross-hatching shadows, cel-shaded flat colors, "
                 "desaturated muted palette, grunge textures, solid bright lime green background #7FFF00",
        "path": "sprites/enemies/possessed_slave.png",
    },
    {
        "id": "possessed_guard",
        "object": "a possessed ancient Mesopotamian warrior guard, dented bent bronze armor, "
                  "one shoulder plate pushed unnaturally high, neck twisted at wrong angle, "
                  "holding broken spear, body deformed under armor, "
                  "pure black eyes with dark pulsating veins, heavy menacing presence",
        "accent_color": "tarnished bronze, bruised skin tones",
        "extra": "Tank enemy, front-facing portrait, dark fantasy horror, "
                 "bold rough black ink outlines, cross-hatching shadows, cel-shaded flat colors, "
                 "desaturated muted palette, grunge textures, solid bright lime green background #7FFF00",
        "path": "sprites/enemies/possessed_guard.png",
    },
    {
        "id": "possessed_priest",
        "object": "a possessed ancient Mesopotamian priest levitating above ground, "
                  "torn ritual robes with cuneiform symbols, pure black eyes with dense network "
                  "of dark pulsating veins across entire face, hands raised in ritual gestures, "
                  "dark smoke trailing from fingertips, shaved head with ritual scarification",
        "accent_color": "dark purple accents, faded ritual white robes turned gray",
        "extra": "Caster enemy, front-facing portrait, dark fantasy horror, "
                 "bold rough black ink outlines, cross-hatching shadows, cel-shaded flat colors, "
                 "desaturated muted palette, grunge textures, solid bright lime green background #7FFF00",
        "path": "sprites/enemies/possessed_priest.png",
    },
    {
        "id": "the_torn",
        "object": "a human possessed by multiple dark spirits simultaneously, "
                  "grotesquely swollen body literally tearing apart, ghostly clawed hands burst "
                  "through cracks in the skin, black smoke pours from fissures in flesh, "
                  "face split with multiple overlapping mouths, eyes are hollow black voids, "
                  "massive towering figure radiating dark energy, extreme body horror",
        "accent_color": "muted burgundy raw flesh, sickly green undertones",
        "extra": "Elite enemy, front-facing portrait, dark fantasy horror, "
                 "bold rough black ink outlines, cross-hatching shadows, cel-shaded flat colors, "
                 "desaturated muted palette, grunge textures, solid bright lime green background #7FFF00",
        "path": "sprites/enemies/the_torn.png",
    },
    {
        "id": "ashipu",
        "object": "Ashipu, possessed high priest boss, tall imposing figure in torn elaborate "
                  "Mesopotamian priestly robes with tarnished gold trim, levitating above ground, "
                  "skin covered in deep cracks with black smoke seeping through, "
                  "eyes are two black voids with flickering purple fire within, "
                  "halo of slowly rotating glowing cuneiform symbols orbits around head, "
                  "arms outstretched dark energy crackling between fingers, half-human half-spirit",
        "accent_color": "decayed gold, deep purple accents, ash gray skin",
        "extra": "Epic boss character, imposing and grand, front-facing portrait, "
                 "larger and more detailed than regular enemies, dark fantasy horror, "
                 "bold rough black ink outlines, cross-hatching shadows, cel-shaded flat colors, "
                 "desaturated muted palette, grunge textures, solid bright lime green background #7FFF00",
        "path": "sprites/enemies/ashipu.png",
    },
]

CARDS = [
    # ATTACKS
    {
        "id": "basic_strike",
        "object": "a simple but powerful sword strike, a warrior's blade cutting through dark air, "
                  "sparks of golden energy on impact",
        "accent_color": "blood red slash energy",
        "extra": "Card illustration, contained within implicit card frame, action-oriented",
    },
    {
        "id": "vocabulary_slash",
        "object": "a magical sword made of glowing letters and words, slashing through darkness, "
                  "vocabulary words trailing behind the blade like a comet tail",
        "accent_color": "blood red and golden word energy",
        "extra": "Card illustration, dynamic slashing motion, magical word particles",
    },
    {
        "id": "past_simple_strike",
        "object": "an ancient rusted sword wreathed in time-distortion energy, "
                  "striking from the past through a temporal rift, clock fragments flying",
        "accent_color": "amber temporal glow, sepia time-distortion",
        "extra": "Card illustration, past/time theme, nostalgic and powerful",
    },
    {
        "id": "definition_bolt",
        "object": "a bolt of pure knowledge energy, a beam of light made of dictionary definitions, "
                  "fired from an open ancient book, lightning-like",
        "accent_color": "glowing arcane blue lightning",
        "extra": "Card illustration, energy projectile, magical and scholarly",
    },
    {
        "id": "preposition_punch",
        "object": "a gauntleted fist surrounded by orbiting preposition symbols (in, on, at), "
                  "delivering a powerful magical punch, shockwave on impact",
        "accent_color": "blood red impact energy",
        "extra": "Card illustration, close combat, dynamic punch motion",
    },
    {
        "id": "irregular_inferno",
        "object": "a massive eruption of chaotic magical fire, flames shaped like irregular verb conjugations, "
                  "a burning spellbook at the center of the inferno",
        "accent_color": "blood red and orange inferno flames",
        "extra": "Card illustration, multi-hit fire attack, chaotic and powerful",
    },
    {
        "id": "conditional_cleave",
        "object": "a massive two-handed axe splitting reality into two conditional paths (if/then), "
                  "the blade creating a rift showing two alternate outcomes",
        "accent_color": "glowing arcane blue rift energy",
        "extra": "Card illustration, powerful cleaving motion, reality-splitting theme",
    },
    {
        "id": "comparative_slash",
        "object": "twin blades of different sizes (bigger/smaller) crossing in a scissor slash, "
                  "comparison symbols floating between them, scales of balance",
        "accent_color": "blood red blade energy with golden comparison symbols",
        "extra": "Card illustration, dual blade attack, comparative/scaling theme",
    },
    {
        "id": "passive_voice_wall",
        "object": "a spectral shield that simultaneously projects attacking shadow tendrils, "
                  "defense and offense combined, a wall of ghostly passive energy",
        "accent_color": "glowing arcane blue defensive and blood red offensive energy",
        "extra": "Card illustration, hybrid attack/defense, spectral and mysterious",
    },
    {
        "id": "plural_smash",
        "object": "multiple giant fists (plural) smashing down simultaneously, "
                  "duplicating on impact, ground cracking beneath",
        "accent_color": "blood red impact shockwaves",
        "extra": "Card illustration, multiplication/plural theme, heavy impact",
    },
    {
        "id": "phrasal_verb_strike",
        "object": "a warrior performing a complex multi-part attack combo, "
                  "each strike phase connected by glowing verb particles, "
                  "a chain of linked magical strikes",
        "accent_color": "blood red chain-link energy between strikes",
        "extra": "Card illustration, combo/chain attack, multi-phase motion",
    },
    {
        "id": "spelling_arrow",
        "object": "a magical arrow made entirely of crystallized letters, "
                  "fired from a bone bow, leaving a trail of alphabet sparks, "
                  "piercing through darkness",
        "accent_color": "glowing arcane blue arrow trail",
        "extra": "Card illustration, ranged projectile, precision and spelling theme",
    },
    # SKILLS
    {
        "id": "basic_defend",
        "object": "a sturdy shield made of bound leather and parchment pages, "
                  "glowing with protective blue runes, blocking incoming attacks",
        "accent_color": "glowing arcane blue protective runes",
        "extra": "Card illustration, defensive stance, solid and protective",
    },
    {
        "id": "present_shield",
        "object": "a translucent temporal shield showing the present moment, "
                  "a clock frozen at NOW, protective bubble of present-tense energy",
        "accent_color": "glowing arcane blue temporal shield energy",
        "extra": "Card illustration, time/present theme, protective and serene",
    },
    {
        "id": "article_guard",
        "object": "three floating magical shields labeled with arcane grammar symbols (a, an, the), "
                  "orbiting a defensive stance figure, each shield a different size",
        "accent_color": "glowing arcane blue shield barriers",
        "extra": "Card illustration, grammar/article theme, triple defense",
    },
    {
        "id": "tense_shield",
        "object": "an hourglass-shaped shield with sand flowing inside it, "
                  "past-present-future protection, temporal barrier",
        "accent_color": "golden sand glow inside the hourglass shield",
        "extra": "Card illustration, time/tense theme, temporal defense",
    },
    {
        "id": "word_order_barrier",
        "object": "a magical wall made of rearranging stone blocks with runes, "
                  "the blocks shifting into correct order to form an impenetrable barrier",
        "accent_color": "glowing arcane blue rune light between blocks",
        "extra": "Card illustration, construction/order theme, puzzle-like defense",
    },
    {
        "id": "synonym_swap",
        "object": "two glowing orbs of energy swapping places in a figure-eight pattern, "
                  "each containing different but related magical symbols, "
                  "a hand directing the swap",
        "accent_color": "glowing arcane blue and emerald green swap trails",
        "extra": "Card illustration, utility/swap theme, elegant and flowing",
    },
    {
        "id": "pronoun_parry",
        "object": "a fencer in elegant parry stance, their rapier deflecting an attack, "
                  "magical pronoun symbols (I, you, he, she) forming a defensive arc",
        "accent_color": "glowing arcane blue parry energy arc",
        "extra": "Card illustration, precise defensive technique, fencing theme",
    },
    {
        "id": "collocation_cover",
        "object": "interlocking puzzle pieces forming a protective dome, "
                  "each piece a different word that fits together perfectly, "
                  "magical seams glowing where pieces connect",
        "accent_color": "emerald green connection glow between pieces",
        "extra": "Card illustration, combination/synergy theme, protective dome",
    },
]

RELICS = [
    {
        "id": "golden_dictionary",
        "object": "a thick ancient golden dictionary book, ornate binding with gemstones, "
                  "glowing pages visible from slightly open cover, floating with magical energy",
        "accent_color": "golden light emanating from the pages",
        "extra": "Small icon, 64x64 style, clean silhouette, relic/artifact feel, "
                 "contained within a subtle golden border frame",
        "path": "sprites/relics/golden_dictionary.png",
    },
    {
        "id": "phonetic_ankh",
        "object": "an Egyptian ankh symbol made of crystallized sound waves, "
                  "phonetic symbols etched into its surface, ancient and mystical",
        "accent_color": "glowing arcane blue sound-wave energy",
        "extra": "Small icon, 64x64 style, clean silhouette, relic/artifact feel, "
                 "contained within a subtle golden border frame",
        "path": "sprites/relics/phonetic_ankh.png",
    },
    {
        "id": "etymology_lens",
        "object": "an ornate magnifying glass with ancient root words visible through the lens, "
                  "brass and leather construction, scholarly artifact",
        "accent_color": "warm amber light through the lens",
        "extra": "Small icon, 64x64 style, clean silhouette, relic/artifact feel, "
                 "contained within a subtle golden border frame",
        "path": "sprites/relics/etymology_lens.png",
    },
    {
        "id": "speed_readers_monocle",
        "object": "an elegant steampunk monocle with tiny clockwork gears, "
                  "the lens shows accelerated text scrolling, time-enhancing artifact",
        "accent_color": "golden clockwork glow and lens gleam",
        "extra": "Small icon, 64x64 style, clean silhouette, relic/artifact feel, "
                 "contained within a subtle golden border frame",
        "path": "sprites/relics/speed_readers_monocle.png",
    },
    {
        "id": "polyglots_amulet",
        "object": "a mystical amulet necklace with a central gemstone surrounded by symbols "
                  "from many languages (Latin, Greek, Cyrillic, Arabic), radiating multilingual power",
        "accent_color": "emerald green core gem glow with multi-colored language symbol sparks",
        "extra": "Small icon, 64x64 style, clean silhouette, relic/artifact feel, "
                 "contained within a subtle golden border frame",
        "path": "sprites/relics/polyglots_amulet.png",
    },
]

BACKGROUNDS = [
    {
        "id": "combat_bg",
        "object": "a dark gothic library dungeon interior, towering bookshelves fading into shadow, "
                  "scattered ancient scrolls and broken quill pens on the floor, "
                  "dim candlelight casting long shadows, stone floor with carved runes",
        "accent_color": "warm orange candlelight and cold blue moonlight from a distant window",
        "extra": "Wide landscape composition, atmospheric environment, no characters, "
                 "suitable as a combat arena background, horizontal 16:9 aspect ratio, "
                 "dark and moody with space for UI elements",
        "path": "sprites/ui/combat_bg.png",
    },
    {
        "id": "main_menu_bg",
        "object": "a massive dark tower (the Spire) rising into stormy clouds, "
                  "viewed from below, the tower is made of giant stacked books and stone, "
                  "lightning illuminating arcane symbols on its surface, "
                  "a winding staircase spiraling upward",
        "accent_color": "golden lightning and arcane window-glow from the tower",
        "extra": "Vertical-emphasis composition but landscape format, epic and foreboding, "
                 "title screen background, horizontal 16:9 aspect ratio, "
                 "dark sky with dramatic clouds, space for title text overlay",
        "path": "sprites/ui/main_menu_bg.png",
    },
    {
        "id": "map_bg",
        "object": "an ancient weathered parchment map spread on a stone table, "
                  "the map shows a winding path up through a tower, "
                  "ink drawings of locations along the path, compass rose in corner, "
                  "coffee stains and wax seal marks",
        "accent_color": "warm sepia tones with golden ink highlights on the path",
        "extra": "Top-down view of the parchment, aged paper texture, "
                 "horizontal 16:9 aspect ratio, subtle and not too busy, "
                 "serves as background for interactive map nodes",
        "path": "sprites/ui/map_bg.png",
    },
    {
        "id": "shop_bg",
        "object": "a cluttered magical bookshop interior, shelves lined with potions and rare tomes, "
                  "a wooden counter with scales and coins, "
                  "warm lantern light, mysterious artifacts on display, "
                  "a cozy but mysterious merchant's den",
        "accent_color": "warm golden lantern light and cool blue potion glow",
        "extra": "Interior scene, inviting but mysterious, "
                 "horizontal 16:9 aspect ratio, warm atmosphere, "
                 "space for shop UI overlay",
        "path": "sprites/ui/shop_bg.png",
    },
    {
        "id": "rest_site_bg",
        "object": "a peaceful campfire scene inside a ruined library alcove, "
                  "warm crackling fire with floating ember particles, "
                  "comfortable bedroll and open books nearby, "
                  "moonlight filtering through broken ceiling, "
                  "a moment of calm in the dungeon",
        "accent_color": "warm orange firelight dominating, with cool blue moonlight contrast",
        "extra": "Cozy and peaceful atmosphere, contrast to combat scenes, "
                 "horizontal 16:9 aspect ratio, calming mood, "
                 "space for rest options UI",
        "path": "sprites/ui/rest_site_bg.png",
    },
]

MAP_ICONS = [
    {
        "id": "icon_combat",
        "object": "a single crossed swords icon, simple fantasy combat symbol, metallic blades",
        "accent_color": "blood red blade gleam",
        "extra": "Tiny icon, 48x48 style, clean simple silhouette on transparent background, "
                 "minimal detail, instantly recognizable at small size, symbolic icon",
        "path": "sprites/ui/icon_combat.png",
    },
    {
        "id": "icon_elite",
        "object": "a horned skull icon, elite enemy symbol, menacing with small horns",
        "accent_color": "dark crimson red glow in eye sockets",
        "extra": "Tiny icon, 48x48 style, clean simple silhouette on transparent background, "
                 "minimal detail, more threatening than regular combat icon, symbolic icon",
        "path": "sprites/ui/icon_elite.png",
    },
    {
        "id": "icon_rest",
        "object": "a small campfire icon with three flames, warm and inviting rest symbol",
        "accent_color": "warm orange flame glow",
        "extra": "Tiny icon, 48x48 style, clean simple silhouette on transparent background, "
                 "minimal detail, cozy feeling, symbolic icon",
        "path": "sprites/ui/icon_rest.png",
    },
    {
        "id": "icon_shop",
        "object": "a coin purse or bag of gold coins icon, commerce and shop symbol",
        "accent_color": "golden coin gleam",
        "extra": "Tiny icon, 48x48 style, clean simple silhouette on transparent background, "
                 "minimal detail, wealth/trade symbol, symbolic icon",
        "path": "sprites/ui/icon_shop.png",
    },
    {
        "id": "icon_event",
        "object": "a question mark inside a mystical orb icon, unknown event symbol, mysterious",
        "accent_color": "glowing purple mystical energy",
        "extra": "Tiny icon, 48x48 style, clean simple silhouette on transparent background, "
                 "minimal detail, mysterious and intriguing, symbolic icon",
        "path": "sprites/ui/icon_event.png",
    },
    {
        "id": "icon_boss",
        "object": "a menacing crown with spikes icon, final boss symbol, imposing and dark",
        "accent_color": "golden crown with blood red gem",
        "extra": "Tiny icon, 56x56 style, clean simple silhouette on transparent background, "
                 "slightly larger and more detailed than other icons, boss/king symbol",
        "path": "sprites/ui/icon_boss.png",
    },
    {
        "id": "icon_library",
        "object": "an open book icon, library/knowledge symbol, pages fanned open",
        "accent_color": "glowing arcane blue page light",
        "extra": "Tiny icon, 48x48 style, clean simple silhouette on transparent background, "
                 "minimal detail, scholarly and inviting, symbolic icon",
        "path": "sprites/ui/icon_library.png",
    },
]


EXTRA_ASSETS = [
    {
        "id": "card_back",
        "object": "the back side of a mystical card/tarot card, ornate symmetrical design with "
                  "interlocking runic patterns, a central ancient book emblem surrounded by "
                  "swirling arcane energy vines, leather-bound texture border, "
                  "dark parchment with embossed golden filigree pattern",
        "accent_color": "deep gold filigree lines and a subtle blue arcane glow in the center emblem",
        "extra": "Card back design, perfectly symmetrical, ornate border pattern, "
                 "dark brown/sepia base with gold accents, 140x200 portrait orientation, "
                 "no text, decorative and mysterious, suitable as playing card reverse side",
        "path": "sprites/ui/card_back.png",
    },
    {
        "id": "hero_portrait",
        "object": "a young scholarly adventurer/mage character, wearing a hooded traveling cloak "
                  "over light leather armor, carrying a magical tome chained to their belt, "
                  "one hand holding a glowing quill that serves as a wand, "
                  "determined expression, scarf covering lower face, intelligent eyes",
        "accent_color": "glowing arcane blue from the quill-wand and golden light from the tome's pages",
        "extra": "Character portrait, front-facing, upper body and head visible, "
                 "on a solid dark uniform background (nearly black), clean edges for easy extraction, "
                 "heroic but scholarly feel, the protagonist of a knowledge-based adventure, "
                 "160x200 portrait style, no background clutter",
        "path": "sprites/ui/hero_portrait.png",
    },
]


def generate_image(asset_def, category="card"):
    """Call OpenRouter API to generate an image from the asset definition."""
    prompt = BASE_STYLE.format(
        object=asset_def["object"],
        accent_color=asset_def["accent_color"],
        extra=asset_def.get("extra", ""),
    )

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/lexica-spire",
        "X-Title": "Lexica Spire Asset Generator",
    }

    payload = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"Generate an image based on this description. Return ONLY the image, no text.\n\n{prompt}",
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
            print(f"  [WARN] No choices in response for {asset_def['id']}")
            return None

        message = choices[0].get("message", {})

        # Primary format: message.images[] array with image_url data URIs
        images = message.get("images", [])
        if images:
            for img in images:
                if isinstance(img, dict):
                    url_data = img.get("image_url", {}).get("url", "")
                    if url_data.startswith("data:"):
                        b64 = url_data.split(",", 1)[1]
                        return base64.b64decode(b64)
            print(f"  [WARN] images[] present but no valid data URI for {asset_def['id']}")

        # Fallback: check content for inline parts
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

        print(f"  [WARN] No image in response for {asset_def['id']}")
        if isinstance(content, str) and content:
            print(f"  Text: {content[:200]}")
        return None

    except requests.exceptions.HTTPError as e:
        print(f"  [ERROR] HTTP {e.response.status_code} for {asset_def['id']}: {e.response.text[:300]}")
        return None
    except Exception as e:
        print(f"  [ERROR] {type(e).__name__} for {asset_def['id']}: {e}")
        return None


def save_image(image_bytes, path):
    """Save image bytes to the specified path under GODOT_ASSETS."""
    full_path = os.path.join(GODOT_ASSETS, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "wb") as f:
        f.write(image_bytes)
    print(f"  [OK] Saved: {full_path} ({len(image_bytes)} bytes)")


def process_batch(assets, category, default_path_template=None):
    """Process a batch of asset definitions."""
    total = len(assets)
    success = 0
    failed = []

    for i, asset in enumerate(assets, 1):
        asset_id = asset["id"]
        print(f"\n[{i}/{total}] Generating {category}: {asset_id}...")

        image_data = generate_image(asset, category)

        if image_data:
            path = asset.get("path", default_path_template.format(id=asset_id) if default_path_template else None)
            if path:
                save_image(image_data, path)
                success += 1
            else:
                print(f"  [ERROR] No path defined for {asset_id}")
                failed.append(asset_id)
        else:
            failed.append(asset_id)

        # Rate limiting - wait between requests
        if i < total:
            time.sleep(2)

    return success, failed


def main():
    # Parse command line args for selective generation
    categories = sys.argv[1:] if len(sys.argv) > 1 else ["enemies", "cards", "relics", "backgrounds", "icons", "extra"]

    print("=" * 60)
    print("  LEXICA SPIRE - Asset Generator")
    print(f"  Model: {MODEL}")
    print(f"  Categories: {', '.join(categories)}")
    print("=" * 60)

    all_success = 0
    all_failed = []

    if "enemies" in categories:
        print("\n" + "=" * 40)
        print("  GENERATING ENEMIES")
        print("=" * 40)
        s, f = process_batch(ENEMIES, "enemy")
        all_success += s
        all_failed.extend(f)

    if "cards" in categories:
        print("\n" + "=" * 40)
        print("  GENERATING CARD ART")
        print("=" * 40)
        s, f = process_batch(CARDS, "card", "sprites/cards/{id}.png")
        all_success += s
        all_failed.extend(f)

    if "relics" in categories:
        print("\n" + "=" * 40)
        print("  GENERATING RELICS")
        print("=" * 40)
        s, f = process_batch(RELICS, "relic")
        all_success += s
        all_failed.extend(f)

    if "backgrounds" in categories:
        print("\n" + "=" * 40)
        print("  GENERATING BACKGROUNDS")
        print("=" * 40)
        s, f = process_batch(BACKGROUNDS, "background")
        all_success += s
        all_failed.extend(f)

    if "icons" in categories:
        print("\n" + "=" * 40)
        print("  GENERATING MAP ICONS")
        print("=" * 40)
        s, f = process_batch(MAP_ICONS, "icon")
        all_success += s
        all_failed.extend(f)

    if "extra" in categories:
        print("\n" + "=" * 40)
        print("  GENERATING EXTRA ASSETS (card back, hero)")
        print("=" * 40)
        s, f = process_batch(EXTRA_ASSETS, "extra")
        all_success += s
        all_failed.extend(f)

    # Summary
    total = all_success + len(all_failed)
    print("\n" + "=" * 60)
    print(f"  DONE: {all_success}/{total} assets generated successfully")
    if all_failed:
        print(f"  FAILED: {', '.join(all_failed)}")
    print("=" * 60)


if __name__ == "__main__":
    main()
