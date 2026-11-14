"""Package actual exported viewport captures, never generated concept images.

Silent sampled sequences have approximate playback cadence; not human playtests.
"""
from pathlib import Path
from PIL import Image
import json, shutil
import imageio_ffmpeg

root = Path(__file__).resolve().parents[1]
source = root/'tools/qa-data/living-export/Godot/app_userdata/OUTLAW SYNDICATE/living-verification'
acting = root/'tools/qa-data/living-export-physics/Godot/app_userdata/OUTLAW SYNDICATE/physics-verification'
out = root/'docs/evidence/living-city'
out.mkdir(parents=True, exist_ok=True)
for p in source.glob('*.png'):
    if p.name.startswith(('contact-', 'signature-run-')):
        continue
    Image.open(p).convert('RGB').save(out/(p.stem+'.jpg'), quality=92)
shutil.copy2(source/'performance.json', out/'performance.json')
sequences = [('signature-run', sorted(source.glob('signature-run-*.png')), 50)]
for speed in [3,12,23]:
    sequences.append((f'contact-{speed}', sorted(source.glob(f'contact-{speed:02d}-*.png')),50))
speech = sorted(acting.glob('acting-*.png'))
if speech:
    sequences.append(('dialogue',speech,120))
    for i in [0,len(speech)//2,len(speech)-1]:
        Image.open(speech[i]).convert('RGB').save(out/f'dialogue-{i:02d}.jpg',quality=92)
for name, paths, duration in sequences:
    if not paths:
        continue
    images = [Image.open(p).convert('RGB').resize((960,540)) for p in paths]
    images[0].save(out/(name+'.gif'),save_all=True,append_images=images[1:],duration=duration,loop=0)
    writer=imageio_ffmpeg.write_frames(str(out/(name+'.mp4')),(960,540),fps=1000/duration,codec='libx264',pix_fmt_in='rgb24',pix_fmt_out='yuv420p',macro_block_size=2,output_params=['-crf','20'])
    writer.send(None)
    for im in images:
        writer.send(im.tobytes())
    writer.close()
metadata={'source':'Actual living-city-signature Windows executable viewport captures',
          'route':'Automated physics/input scenarios, not a human keyboard/gamepad playthrough',
          'clips':'Silent sampled frames; approximate cadence, capture overhead changes timing',
          'visual_status':'Early prototype art; reference parity NOT achieved',
          'performance':'Separate uncapped short 1080p Balanced samples without capture during measurement'}
(out/'capture-provenance.json').write_text(json.dumps(metadata,indent=2)+'\n')
print('Packaged actual exported captures')
