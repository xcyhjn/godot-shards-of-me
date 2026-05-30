"""
将 assets/images/items/ 下所有 PNG 等比缩放到最长边 <= 128px，
输出到同层级 items2/ 目录。保留 RGBA 透明通道，使用 LANCZOS 重采样。
小于 128 的图不放大，仅原样复制（保持像素艺术清晰度）。
"""
from pathlib import Path
from PIL import Image

SRC = Path(r"E:/game_dev/godot/godot-shards-of-me/assets/images/items")
DST = Path(r"E:/game_dev/godot/godot-shards-of-me/assets/images/items2")
MAX_SIDE = 128

DST.mkdir(parents=True, exist_ok=True)

for png in sorted(SRC.glob("*.png")):
    with Image.open(png) as im:
        im.load()
        w, h = im.size
        long_side = max(w, h)
        if long_side <= MAX_SIDE:
            # 已经在限制内，原样保存
            im.save(DST / png.name)
            print(f"[keep] {png.name}  {w}x{h}")
            continue
        scale = MAX_SIDE / long_side
        new_size = (max(1, round(w * scale)), max(1, round(h * scale)))
        # RGBA 模式下 LANCZOS 既保细节又不撕透明边
        if im.mode != "RGBA":
            im = im.convert("RGBA")
        resized = im.resize(new_size, Image.LANCZOS)
        resized.save(DST / png.name)
        print(f"[resize] {png.name}  {w}x{h} -> {new_size[0]}x{new_size[1]}")

print("done.")
