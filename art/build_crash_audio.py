"""Original short crash/glass feedback: deterministic oscillators/noise, no samples."""
import wave,random,math,struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets/audio'
for name in ['crash','glass_break']:
 rng=random.Random(81 if name=='crash' else 86);rate=22050;samples=[]
 for i in range(int(rate*.65)):
  t=i/rate;noise=rng.uniform(-1,1)
  if name=='crash': sample=(noise*.5+math.sin(t*math.tau*(65+30*math.exp(-t*30)))*.35)*math.exp(-t*9)
  else: sample=(noise*.35+sum(math.sin(t*math.tau*f)*.07 for f in [1731,2453,3779,4187]))*math.exp(-t*7)*(0.5+0.5*math.sin(t*91)**2)
  samples.append(struct.pack('<h',int(max(-1,min(1,sample))*25000)))
 with wave.open(str(root/(name+'.wav')),'wb') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(b''.join(samples))
