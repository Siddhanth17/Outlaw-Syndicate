"""Curate Kenney CC0 material foley into normalized surface banks.

Requires the publisher's Impact Sounds archive extracted under tools/downloads.
No generated voice or existing character assets are modified.
"""
from pathlib import Path
import hashlib, json, shutil, subprocess, wave
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
source = ROOT/'tools/downloads/kenney-impact/Audio'
out = ROOT/'assets/audio/movement'
out.mkdir(parents=True, exist_ok=True)
profiles = {}
provenance = []
# Some profiles intentionally share a physical source family with different EQ.
banks = {
    'asphalt': ('footstep_concrete', 'highpass=f=90,lowpass=f=4800', -2, 0.94),
    'concrete': ('footstep_concrete', 'highpass=f=65,lowpass=f=6500', -3, 1.0),
    'warehouse': ('footstep_concrete', 'highpass=f=80,lowpass=f=6000,aecho=0.8:0.6:45:0.13', -4, 0.95),
    'metal': ('impactMetal_light', 'highpass=f=130,lowpass=f=5200', -8, 0.94),
    'dirt': ('footstep_grass', 'highpass=f=80,lowpass=f=2800', -4, 0.9),
    'grass': ('footstep_grass', 'highpass=f=110,lowpass=f=5200', -5, 1.0),
    'wood': ('footstep_wood', 'highpass=f=80,lowpass=f=5200', -5, 0.96),
    'interior': ('footstep_wood', 'highpass=f=100,lowpass=f=4500,aecho=0.8:0.6:32:0.10', -6, 1.08),
    'stairs': ('footstep_concrete', 'highpass=f=70,lowpass=f=6200,aecho=0.8:0.6:38:0.10', -4, 0.92),
    'cloth': ('impactSoft_medium', 'highpass=f=250,lowpass=f=2800', -18, 0.9),
}
for material, (family, filters, gain, pitch) in banks.items():
    paths=[]
    for i in range(4):
        src=source/f'{family}_{i:03d}.ogg'
        dest=out/f'{material}_{i:02d}.wav'
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-v','error','-y','-i',str(src),'-af',filters+',alimiter=limit=0.7:level=0','-ac','1','-ar','24000','-c:a','pcm_s16le',str(dest)],check=True)
        paths.append(dest.relative_to(ROOT).as_posix().replace('assets/','res://assets/',1))
        provenance.append({'output':dest.relative_to(ROOT).as_posix(),'source':src.name,'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'processing':filters,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
    profiles[material]={'samples':paths,'gain_db':gain,'pitch':pitch,'source_family':family}
(ROOT/'data/movement_audio.json').write_text(json.dumps(profiles,indent=2)+'\n')
shutil.copy2(source.parent/'License.txt',ROOT/'assets/licenses/Kenney-Impact-Sounds-CC0.txt')
notice={'author':'Kenney','pack':'Impact Sounds 1.0','license':'CC0-1.0','page':'https://kenney.nl/assets/impact-sounds','archive_sha256':hashlib.sha256((source.parent.parent/'kenney-impact-current.zip').read_bytes()).hexdigest(),'scope':'Nine surface profiles plus cloth. Asphalt/concrete/warehouse/stairs share concrete recordings with different EQ/tails; dirt uses grass recordings. Metal and cloth use curated impact foley, not dedicated boot/jacket recording sessions. Short authored echo tails, not dynamic room acoustics.','files':provenance}
(ROOT/'assets/licenses/movement-audio-provenance.json').write_text(json.dumps(notice,indent=2)+'\n')
print('Created',len(provenance),'credited, surface-curated movement samples')
