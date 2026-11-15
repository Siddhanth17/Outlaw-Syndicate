"""Original deterministic procedural game sounds; no recordings or third-party inputs."""
from pathlib import Path
import json,hashlib,wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio/veyra3'
SR=44100
rng=np.random.default_rng(7103)
manifest={}
def save(name,x,loop=False):
    x=np.asarray(x,dtype=float);x-=x.mean();x*=.82/max(float(np.max(np.abs(x))),1e-9)
    if not loop:
        x[:80]*=np.linspace(0,1,80);x[-800:]*=np.linspace(1,0,800)
    path=OUT/(name+'.wav')
    with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes((x*32767).astype('<i2').tobytes())
    manifest[name]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seconds':len(x)/SR,'peak':float(np.max(np.abs(x))),'loop':loop,'seam_delta':float(abs(x[-1]-x[0]))}
def noise(n,low,high):
    f=np.fft.rfftfreq(n,1/SR);a=np.fft.rfft(rng.normal(size=n));a*=((f>=low)&(f<=high));return np.fft.irfft(a,n)
OUT.mkdir(parents=True,exist_ok=True)
for vehicle,freqs in [('car',[40,70,110]),('bike',[30,60,100])]:
    t=np.arange(SR*3)/SR
    for stage,f in zip(['idle','mid','high'],freqs):
        phase=t*f*2*np.pi
        body=sum(np.sin(phase*h+.15*h)/(h**1.25) for h in range(1,18))
        if vehicle=='bike':body+=.65*sum(np.sin((phase+.43*2*np.pi)*h)/(h**1.2) for h in range(1,15))
        texture=noise(len(t),120,4000)
        x=np.tanh(body*1.15)+texture*.16*(.65+.35*np.sin(phase))
        save(vehicle+'_'+stage,x,True)
    save(vehicle+'_load',noise(len(t),160,2600)*(1+.4*np.sin(t*2*np.pi*freqs[1])),True)
    save(vehicle+'_coast',noise(len(t),90,1800)+.7*np.sin(t*2*np.pi*freqs[0]),True)
    t=np.arange(int(SR*.22))/SR
    save(vehicle+'_shift',noise(len(t),180,1800)*np.exp(-t*24)+np.sin(t*2*np.pi*140)*np.exp(-t*40))
t=np.arange(SR*3)/SR
save('road_roll',noise(len(t),100,1800),True)
for i in range(4):
    t=np.arange(int(SR*.9))/SR
    x=noise(len(t),800,14000)*np.exp(-t*210)*2.2
    x+=noise(len(t),90,1800)*np.exp(-t*28)*1.4
    x+=np.sin(2*np.pi*(110+i*13)*t)*np.exp(-t*37)*.7
    x+=noise(len(t),350,3500)*np.exp(-t*8)*.12
    save('sidearm_%d'%i,x)
(ROOT/'assets/licenses/veyra3-audio-provenance.json').write_text(json.dumps({'author':'Outlaw Syndicate project','license':'CC0-1.0','source':'Original mathematical synthesis, deterministic NumPy generator art/build_veyra3_audio.py. No sampled recordings, brands, cloned voices or external assets.','sample_rate':SR,'files':manifest},indent=2))
print('Authored',len(manifest),'original audio assets')
