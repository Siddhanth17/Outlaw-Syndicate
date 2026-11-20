"""Original periodic wood grain, leather pores and woven fabric maps (CC0-1.0)."""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/textures';N=1024
rng=np.random.default_rng(182)
y,x=np.mgrid[0:N,0:N]/N
noise=rng.normal(size=(N,N))
def smooth(a,amount):
    fy=np.fft.fftfreq(N)[:,None];fx=np.fft.fftfreq(N)[None,:]
    return np.fft.ifft2(np.fft.fft2(a)*np.exp(-(fx*fx+fy*fy)*amount)).real
flow=smooth(noise,7000);flow/=np.std(flow)
grain=np.sin(2*np.pi*(x*54+.3*np.sin(2*np.pi*y*2)+flow*.3))
grain+=.35*np.sin(2*np.pi*(x*117+flow*.6))
wood=.018*grain+.025*flow+.006*noise
leather=.035*smooth(noise,100)+.018*noise
weave=.035*np.sin(2*np.pi*x*180)*np.sin(2*np.pi*y*180)+.015*noise
records={}
for name,base,height in [('vale-oak',(.43,.29,.17),wood),('vale-leather',(.32,.16,.075),leather),('vale-linen',(.60,.56,.44),weave),('vale-quilt',(.18,.28,.32),weave)]:
    rgb=np.clip(np.array(base)[None,None,:]+height[:,:,None]*np.array([1,.8,.6]),0,1)
    path=OUT/(name+'.png');Image.fromarray((rgb*255).astype('uint8')).save(path)
    gy,gx=np.gradient(height);normal=np.stack([-gx*7,-gy*7,np.ones_like(height)],axis=-1);normal/=np.linalg.norm(normal,axis=-1)[:,:,None]
    normal_path=OUT/(name+'-normal.png');Image.fromarray(((normal*.5+.5)*255).astype('uint8')).save(normal_path)
    for p in [path,normal_path]:records[p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
(ROOT/'assets/licenses/vale-home-provenance.json').write_text(json.dumps({'license':'CC0-1.0','source':'Original NumPy mathematical textures and Blender geometry; see art/build_home_surfaces.py and art/build_vale_home.py. The existing Poly Haven concrete plaster maps retain their original CC0 provenance. No downloaded models or private reference images.','files':records},indent=2),encoding='utf-8')
