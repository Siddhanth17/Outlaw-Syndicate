"""Own Windows-export viewport evidence; never generated concept/reference images."""
from pathlib import Path
from PIL import Image
import json, shutil
import imageio_ffmpeg

r=Path(__file__).resolve().parents[1]
s=r/'tools/qa-data/articulated-final/Godot/app_userdata/OUTLAW SYNDICATE/ragdoll-verification'
out=r/'docs/evidence/articulated-physics';out.mkdir(parents=True,exist_ok=True)
for p in s.glob('*.png'):
    if p.stem.endswith(('-rest','-fall')) or p.stem=='populated-physics-budget':
        Image.open(p).convert('RGB').save(out/(p.stem+'.jpg'),quality=92)
before=r/'tools/qa-data/ragdoll-before/Godot/app_userdata/OUTLAW SYNDICATE/living-verification/vehicle-npc-knockdown.png'
if before.exists():Image.open(before).convert('RGB').save(out/'before-rigid-knockdown.jpg',quality=92)
for name in ['physics-results.json','performance.json']:shutil.copy2(s/name,out/name)
for kind in ['frontal','side','running','wall','stairs','slope']:
    paths=sorted(p for p in s.glob(kind+'-*.png') if p.stem.split('-')[-1].isdigit())
    if not paths:continue
    images=[Image.open(p).convert('RGB').resize((960,540)) for p in paths]
    images[0].save(out/(kind+'.gif'),save_all=True,append_images=images[1:],duration=200,loop=0)
    writer=imageio_ffmpeg.write_frames(str(out/(kind+'.mp4')),(960,540),fps=5,codec='libx264',pix_fmt_in='rgb24',pix_fmt_out='yuv420p',macro_block_size=2,output_params=['-crf','20'])
    writer.send(None)
    for im in images:writer.send(im.tobytes())
    writer.close()
(out/'provenance.json').write_text(json.dumps({
    'source':'Actual articulated-physics Windows executable viewport captures',
    'input':'Automated damage, physics and player-fire routes; not a full human keyboard/gamepad playthrough',
    'timing':'Silent sampled frames, approximately twelve physics ticks apart. Encoding overhead changes real-time cadence; not synchronized audio/video.',
    'before':'Preserved reference-mobility Windows export e6b5317; different camera/lighting, not a matched pixel comparison',
    'art':'Original/previously credited game assets; no concept art or supplied reference image substituted',
    'fixtures':'White wall/stairs/slope geometry are explicitly labeled engineering collision fixtures, not finished city art'
},indent=2)+'\n')
print('Packaged actual articulated Windows evidence')
