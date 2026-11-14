"""Package actual exported viewport frames; no synthesized/reconstructed game visuals.
Clips are silent sequences from the automated route, not human input recordings.
"""
from pathlib import Path
from PIL import Image
import json,shutil,subprocess
import imageio_ffmpeg
r=Path(__file__).resolve().parents[1]
s=r/'tools/qa-data/final-export-physics/Godot/app_userdata/OUTLAW SYNDICATE/physics-verification'
e=r/'docs/evidence/interaction';e.mkdir(parents=True,exist_ok=True)
for name in ['exploration','front-crash','front-left','right-side','glass-impact','cracked-window','shattered-window','detached-bumper']:
 p=s/(name+'.png')
 if p.exists():Image.open(p).convert('RGB').save(e/(name+'.jpg'),quality=91)
for i in [0,15,25,39]:
 p=s/('acting-%02d.png'%i)
 if p.exists():Image.open(p).convert('RGB').save(e/('dialogue-%02d.jpg'%i),quality=91)
shutil.copy2(s/'performance.json',e/'performance.json')
sequences=[('dialogue',sorted(s.glob('acting-*.png')),120)]
crash=sorted((r/'tools/qa-data/export-physics/Godot/app_userdata/OUTLAW SYNDICATE/physics-verification').glob('crash-*-frame-*.png'))
if crash:
 prefix=crash[0].name.split('-frame-')[0]
 sequences.append(('physical-crash',[p for p in crash if p.name.startswith(prefix+'-frame-')],67))
for name,paths,duration in sequences:
 images=[Image.open(p).convert('RGB').resize((960,540)) for p in paths]
 images[0].save(e/(name+'.gif'),save_all=True,append_images=images[1:],duration=duration,loop=0)
 # MP4 uses the same actual frames. Capture overhead may vary timing; no audio track.
 writer=imageio_ffmpeg.write_frames(str(e/(name+'.mp4')),(960,540),fps=1000/duration,codec='libx264',pix_fmt_in='rgb24',pix_fmt_out='yuv420p',macro_block_size=2,output_params=['-crf','20'])
 writer.send(None)
 for im in images:writer.send(im.tobytes())
 writer.close()
print('Packaged exported screenshots and silent motion sequences')
