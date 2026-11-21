"""Original fictional dispatch chirps / short synthesized siren; no recordings."""
from pathlib import Path
import hashlib,json,wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio/law'
OUT.mkdir(parents=True,exist_ok=True)
rate=44100
files={}
for name,seconds in [('call_connected',.32),('radio_chirp',.24),('patrol_siren',2.0)]:
    t=np.arange(int(rate*seconds))/rate
    if name=='patrol_siren':frequency=650+240*np.sin(t*np.pi*2*.8)
    elif name=='radio_chirp':frequency=np.where(t<.12,780,980)
    else:frequency=np.where(t<.16,620,820)
    phase=np.cumsum(np.broadcast_to(frequency,t.shape))*2*np.pi/rate
    envelope=np.minimum(t/.02,1)*np.minimum((seconds-t)/.04,1)
    sound=(np.sin(phase)*.65+np.sin(phase*2)*.12)*envelope*.45
    pcm=(np.clip(sound,-1,1)*32767).astype('<i2')
    path=OUT/(name+'.wav')
    with wave.open(str(path),'wb') as output:
        output.setnchannels(1);output.setsampwidth(2);output.setframerate(rate);output.writeframes(pcm.tobytes())
    files[name]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seconds':seconds,'peak':float(np.abs(sound).max())}
(ROOT/'assets/licenses/veyra4-law-audio-provenance.json').write_text(json.dumps({'license':'CC0-1.0','source':'Original deterministic NumPy sine synthesis in art/build_police_audio.py; no sampled recordings or cloned voices','sample_rate':rate,'files':files},indent=2),encoding='utf-8')
print('Generated three original bounded fictional law cues')
