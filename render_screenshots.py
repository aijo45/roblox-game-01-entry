"""Render Neon Coin Rush screenshots (start / play / end) as 1280x720 PNGs.

These depict the game's actual Roblox GUI layout: the 640x480 arena
centered, the HUD on the right, the timer bar on top, and the start/end
overlays exactly as the Luau builds them. They stand in for Studio
captures, which this Linux machine cannot take; the user may replace them
with real Studio captures before submitting.
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.expanduser("~/workspace/makefun/roblox-game-01-entry/screenshots")
W, H = 1280, 720
ARENA_W, ARENA_H = 640, 480
AX, AY = (W - ARENA_W) // 2, (H - ARENA_H) // 2  # arena top-left

BG = (12, 12, 24)
ARENA_BG = (18, 18, 38)
ARENA_BORDER = (60, 60, 120)
CYAN = (0, 229, 255)
GOLD = (255, 200, 40)
GOLD_DARK = (160, 110, 0)
RED = (255, 60, 80)
RED_DARK = (140, 0, 20)
WHITE = (230, 230, 245)
YELLOW = (255, 220, 90)
GREEN = (170, 255, 140)
PINK = (255, 90, 120)
DARK_TEXT = (10, 40, 50)


def font(size, bold=True):
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def text_center(d, cx, y, s, f, fill):
    w = d.textlength(s, font=f)
    d.text((cx - w / 2, y), s, font=f, fill=fill)


def text_right(d, x, y, s, f, fill):
    w = d.textlength(s, font=f)
    d.text((x - w, y), s, font=f, fill=fill)


def rounded_rect(d, box, radius, fill, outline=None, width=1):
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_hud(d, score, lives, time_left, level, combo=None):
    # Score / lives / time / level, right-aligned on the right side.
    f_big, f = font(30), font(22)
    text_right(d, W - 24, 18, f"SCORE  {score}", f_big, CYAN)
    hearts = "♥" * lives + "♡" * (3 - lives)
    text_right(d, W - 24, 56, f"LIVES  {hearts}", f, PINK)
    text_right(d, W - 24, 86, f"TIME  {time_left}", f, YELLOW)
    lvl = f"LEVEL  {level}"
    if combo and combo > 1:
        lvl += f"   COMBO x{combo}"
    text_right(d, W - 24, 116, lvl, f, GREEN)
    # Timer bar, top center.
    d.rounded_rectangle([W // 2 - 160, 14, W // 2 + 160, 24], radius=5, fill=(40, 40, 70))
    frac = max(0.0, min(1.0, time_left / 60.0))
    bar_col = PINK if time_left <= 10 else YELLOW
    d.rounded_rectangle([W // 2 - 160, 14, W // 2 - 160 + int(320 * frac), 24], radius=5, fill=bar_col)


def draw_arena(d):
    d.rectangle([AX, AY, AX + ARENA_W, AY + ARENA_H], fill=ARENA_BG, outline=ARENA_BORDER, width=2)
    # faint grid dots
    for gx in range(AX + 40, AX + ARENA_W, 80):
        for gy in range(AY + 40, AY + ARENA_H, 80):
            d.ellipse([gx - 2, gy - 2, gx + 2, gy + 2], fill=(40, 40, 80))


def draw_player(d, x, y, size=44):
    rounded_rect(d, [AX + x, AY + y, AX + x + size, AY + y + size], radius=11, fill=CYAN, outline=(0, 120, 140), width=2)
    text_center(d, AX + x + size // 2, AY + y + 8, "▶", font(22), DARK_TEXT)


def draw_coin(d, x, y, size=28):
    d.ellipse([AX + x, AY + y, AX + x + size, AY + y + size], fill=GOLD, outline=GOLD_DARK, width=2)
    text_center(d, AX + x + size // 2, AY + y + 3, "$", font(18), (120, 80, 0))


def draw_hazard(d, x, y, size=36):
    rounded_rect(d, [AX + x, AY + y, AX + x + size, AY + y + size], radius=7, fill=RED, outline=RED_DARK, width=2)
    text_center(d, AX + x + size // 2, AY + y + 4, "✕", font(22), (90, 0, 10))


def overlay(d, alpha=38):
    ov = Image.new("RGBA", (W, H), (12, 12, 24, alpha))
    return ov


def start_screen():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img, "RGBA")
    draw_arena(d)
    draw_player(d, (ARENA_W - 44) // 2, (ARENA_H - 44) // 2)
    draw_coin(d, 120, 90)
    draw_coin(d, 480, 320)
    draw_hazard(d, 90, 330)
    img.paste(Image.alpha_composite(img.convert("RGBA"), overlay(d)), (0, 0))
    d = ImageDraw.Draw(img)
    draw_hud(d, 0, 3, 60, 1)
    text_center(d, W // 2, 250, "NEON COIN RUSH", font(52), CYAN)
    text_center(d, W // 2, 330, "Grab the gold coins. Dodge the red hazards.", font(22), WHITE)
    text_center(d, W // 2, 362, "60 seconds. 3 lives. Chain coins for combos!", font(22), WHITE)
    text_center(d, W // 2, 420, "Move: Arrow keys or WASD   •   Press ENTER or click to start", font(19), YELLOW)
    rounded_rect(d, [W // 2 - 110, 470, W // 2 + 110, 526], radius=17, fill=CYAN)
    text_center(d, W // 2, 484, "▶  START", font(26), DARK_TEXT)
    return img


def play_screen():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    draw_arena(d)
    draw_coin(d, 96, 70)
    draw_coin(d, 520, 110)
    draw_coin(d, 300, 200)
    draw_coin(d, 540, 360)
    draw_coin(d, 140, 380)
    draw_hazard(d, 180, 120)
    draw_hazard(d, 420, 250)
    draw_hazard(d, 260, 380)
    draw_player(d, 300, 230)
    draw_hud(d, 40, 3, 42, 2, combo=2)
    return img


def end_screen():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img, "RGBA")
    draw_arena(d)
    draw_coin(d, 120, 90)
    draw_hazard(d, 420, 300)
    draw_player(d, (ARENA_W - 44) // 2, (ARENA_H - 44) // 2)
    img.paste(Image.alpha_composite(img.convert("RGBA"), overlay(d)), (0, 0))
    d = ImageDraw.Draw(img)
    draw_hud(d, 120, 1, 0, 3)
    text_center(d, W // 2, 250, "TIME UP!", font(52), YELLOW)
    text_center(d, W // 2, 330, "Score: 120", font(24), WHITE)
    text_center(d, W // 2, 366, "Coins: 12   •   Level reached: 3", font(24), WHITE)
    text_center(d, W // 2, 430, "Press R or click to play again", font(19), CYAN)
    rounded_rect(d, [W // 2 - 120, 470, W // 2 + 120, 524], radius=16, fill=CYAN)
    text_center(d, W // 2, 482, "↻  PLAY AGAIN", font(24), DARK_TEXT)
    return img


os.makedirs(OUT, exist_ok=True)
for name, fn in (("1-start.png", start_screen), ("2-play.png", play_screen), ("3-end.png", end_screen)):
    img = fn()
    path = os.path.join(OUT, name)
    img.save(path, format="PNG", optimize=True)
    size = os.path.getsize(path)
    print(f"{name}: {img.size} {size} bytes {'OK' if size <= 262144 else 'TOO BIG'}")
