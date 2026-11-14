"""Apply explicit desktop texture budgets after the first Godot import.
Re-run Godot --editor --import --quit afterwards. No runtime/source images edited.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
count=0
for path in [p for p in (root/'assets').rglob('*.import') if p.name.endswith(('.jpg.import','.png.import'))]:
    text=path.read_text(encoding='utf-8')
    text=text.replace('compress/mode=0','compress/mode=2')
    text=text.replace('mipmaps/generate=false','mipmaps/generate=true')
    if 'characters' in path.parts:
        text=text.replace('compress/high_quality=false','compress/high_quality=true')
    if 'normal' in path.name:
        text=text.replace('compress/normal_map=0','compress/normal_map=1')
    path.write_text(text,encoding='utf-8')
    count+=1
print('Configured VRAM-compressed, mipmapped textures:',count)
