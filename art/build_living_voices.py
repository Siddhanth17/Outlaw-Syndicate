"""Original resident call lines using the already installed licensed Kokoro toolchain.
No network, voice cloning, or modification of the prior story recordings.
"""
import os
os.environ['OMP_NUM_THREADS']='4'
from pathlib import Path
import json,hashlib
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
root=Path(__file__).resolve().parents[1]
model=root/'tools/voice-tools/kokoro/kokoro-v1.0.int8.onnx'
voices=root/'tools/voice-tools/kokoro/voices-v1.0.bin'
engine=Kokoro(str(model),str(voices))
profiles=json.loads((root/'data/voice_profiles.json').read_text())['profiles']
folder=root/'assets/audio/living';folder.mkdir(exist_ok=True)
result={}
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
for row in json.loads((root/'data/living_roster.json').read_text())['citizens']:
    preset=profiles[row['voice']]
    samples,rate=engine.create(row['call_line'],voice=preset['voice'],speed=preset['speed'],lang='en-gb' if preset['voice'].startswith('b') else 'en-us')
    rms=float(np.sqrt(np.mean(samples*samples)))
    gain=min(.89/max(.001,float(np.max(np.abs(samples)))),.11/max(.001,rms))
    samples=np.clip(samples*gain,-.89,.89)
    path=folder/(row['id']+'.wav');sf.write(str(path),samples,rate,subtype='PCM_16')
    result[row['id']]={'line':row['call_line'],'audio':'res://'+path.relative_to(root).as_posix(),'preset':preset['voice'],'duration':len(samples)/rate,'peak':float(np.max(np.abs(samples))),'sha256':sha(path)}
    print('LIVING_VOICE',row['id'],flush=True)
for name,duration,freq in [('phone_ring',.5,440),('register',.25,880)]:
    rate=24000;t=np.arange(int(rate*duration))/rate
    samples=.09*np.sin(2*np.pi*freq*t)*np.sin(np.pi*t/duration)
    sf.write(str(folder/(name+'.wav')),samples,rate,subtype='PCM_16')
(root/'data/living_voices.json').write_text(json.dumps(result,indent=2)+'\n')
(root/'assets/licenses/living-voices-provenance.json').write_text(json.dumps({'generator':'kokoro-onnx, local original authored text, generic licensed presets; no cloning','licenses':['Kokoro Apache-2.0','kokoro-onnx MIT'],'model_sha256':sha(model),'voices_sha256':sha(voices),'lines':result,'original_synthesis':['phone_ring.wav','register.wav']},indent=2)+'\n')
print('LIVING_VOICES_COMPLETE',flush=True)
