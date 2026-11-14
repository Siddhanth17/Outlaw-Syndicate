"""Package own exported viewport frames and engine audio, not reference/concept art."""
from pathlib import Path
from PIL import Image
import json, shutil
import imageio_ffmpeg

r=Path(__file__).resolve().parents[1]
m=r/'tools/qa-data/mobility-final/Godot/app_userdata/OUTLAW SYNDICATE/mobility-verification'
c=r/'tools/qa-data/reference-city-final/Godot/app_userdata/OUTLAW SYNDICATE/living-verification'
out=r/'docs/evidence/reference-mobility';out.mkdir(parents=True,exist_ok=True)
for source in [m,c]:
    for p in source.glob('*.png'):
        if p.stem.startswith(('door-sequence','bike-sequence','contact-','signature-run-')):continue
        Image.open(p).convert('RGB').save(out/(p.stem+'.jpg'),quality=92)
shutil.copy2(m/'actual-movement-mix.wav',out/'actual-movement-mix.wav')
shutil.copy2(m/'expanded-performance.json',out/'expanded-performance.json')
shutil.copy2(c/'performance.json',out/'central-performance.json')
for name,paths,duration in [
    ('door-interaction',sorted(m.glob('door-sequence-*.png')),200),
    ('motorcycle',sorted(m.glob('bike-sequence-*.png')),200),
    ('half-tied-running',sorted(c.glob('signature-run-*.png')),50),
]:
    if not paths:continue
    images=[Image.open(p).convert('RGB').resize((960,540)) for p in paths]
    images[0].save(out/(name+'.gif'),save_all=True,append_images=images[1:],duration=duration,loop=0)
    writer=imageio_ffmpeg.write_frames(str(out/(name+'.mp4')),(960,540),fps=1000/duration,codec='libx264',pix_fmt_in='rgb24',pix_fmt_out='yuv420p',macro_block_size=2,output_params=['-crf','20'])
    writer.send(None)
    for im in images:writer.send(im.tobytes())
    writer.close()
(out/'provenance.json').write_text(json.dumps({
    'source':'Actual reference-mobility Windows executable viewport and AudioEffectRecord output mix',
    'input':'Automated physics and input scenarios, not a full human keyboard/gamepad playthrough',
    'clips':'Silent sampled frames; approximate cadence, encoding affects timeline. Audio is separate, not synchronized to video.',
    'reference':'User image inspected locally; not included in this evidence or game assets',
    'quality':'Prototype art and procedural contact animation; reference parity and full campaign incomplete',
    'measurements':'Separate uncapped short 1080p Balanced samples without capture encoding during timed sections'
},indent=2)+'\n')
print('Packaged actual exported mobility evidence')
