"""New original officer lines using the installed licensed generic Kokoro model.
Does not download models, clone voices, or rewrite existing story/resident audio.
"""
import os
os.environ['OMP_NUM_THREADS']='4'
from pathlib import Path
import hashlib,json
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
ROOT=Path(__file__).resolve().parents[1]
model=ROOT/'tools/voice-tools/kokoro/kokoro-v1.0.int8.onnx'
voices=ROOT/'tools/voice-tools/kokoro/voices-v1.0.bin'
engine=Kokoro(str(model),str(voices))
preset='am_fenrir'
assert preset in engine.get_voices()
folder=ROOT/'assets/audio/law';folder.mkdir(exist_ok=True)
lines={}
for key,text in {
    'dispatch_ack':'Patrol One. Responding to the reported incident.',
    'officer_stop':'Stop there. Keep your hands visible.',
    'comply':'Stay still. You are being detained.'
}.items():
    samples,rate=engine.create(text,voice=preset,speed=1.0,lang='en-us')
    if key=='dispatch_ack':
        frequencies=np.fft.rfftfreq(len(samples),1/rate)
        spectrum=np.fft.rfft(samples)
        spectrum*=np.clip((frequencies-200)/150,0,1)*np.clip((3800-frequencies)/400,0,1)
        samples=np.fft.irfft(spectrum,n=len(samples)).astype(np.float32)
    gain=min(.89/max(.001,float(np.abs(samples).max())),.11/max(.001,float(np.sqrt(np.mean(samples*samples)))))
    samples=np.clip(samples*gain,-.89,.89)
    path=folder/(key+'.wav');sf.write(str(path),samples,rate,subtype='PCM_16')
    window=max(1,rate//50)
    envelope=[float(np.sqrt(np.mean(samples[i:i+window]**2))) for i in range(0,len(samples),window)]
    high=max(.001,max(envelope))
    lines[key]={'line':text,'audio':'res://'+path.relative_to(ROOT).as_posix(),'preset':preset,'duration':len(samples)/rate,'peak':float(np.abs(samples).max()),'envelope_hz':50,'envelope':[round(v/high,4) for v in envelope],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    print('OFFICER_VOICE',key,flush=True)
(ROOT/'data/police_voices.json').write_text(json.dumps(lines,indent=2),encoding='utf-8')
(ROOT/'assets/licenses/veyra4-police-voices-provenance.json').write_text(json.dumps({'generator':'Installed kokoro-onnx, original fictional officer text; generic preset, no voice cloning','licenses':['Kokoro Apache-2.0','kokoro-onnx MIT'],'model_sha256':hashlib.sha256(model.read_bytes()).hexdigest(),'voices_sha256':hashlib.sha256(voices.read_bytes()).hexdigest(),'lines':lines},indent=2),encoding='utf-8')
