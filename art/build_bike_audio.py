"""Original unbranded single-cylinder-like synthetic loop; not a recording."""
from pathlib import Path
import math, random, wave, struct
rng=random.Random(842)
values=[]; smooth=0
for i in range(48000):
    t=i/24000
    smooth=.91*smooth+.09*rng.uniform(-1,1)
    pulse=max(0,math.sin(math.tau*38*t))**5
    value=(.18*math.sin(math.tau*76*t)+.10*math.sin(math.tau*152*t)+.15*smooth)*(.35+.65*pulse)
    values.append(struct.pack('<h',int(value*28000)))
with wave.open(str(Path(__file__).resolve().parents[1]/'assets/audio/bike-engine.wav'),'wb') as f:
    f.setparams((1,2,24000,len(values),'NONE','not compressed'));f.writeframes(b''.join(values))
