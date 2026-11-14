"""Original synthesized game audio, no samples or third-party recordings."""
import wave,math,random,struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets/audio'
random.seed(17)
for name,seconds in [('engine',2),('tire',2),('harbor',6),('shot',.22),('reload',.6),('step',.16)]:
    rate=22050;data=[];filtered=0
    for i in range(int(rate*seconds)):
        t=i/rate;noise=random.uniform(-1,1);filtered=.94*filtered+.06*noise
        if name=='engine':v=.25*math.sin(math.tau*60*t)+.16*math.sin(math.tau*120*t)+.08*math.sin(math.tau*180*t)+filtered*.3
        elif name=='tire':v=filtered*.8
        elif name=='harbor':v=filtered*.5+.015*math.sin(math.tau*42*t)*(0.5+.5*math.sin(math.tau*t/6))
        elif name=='shot':v=(noise*.65+math.sin(math.tau*90*t)*.4)*math.exp(-t*26)
        elif name=='step':v=filtered*math.exp(-t*25)*4
        else:v=noise*.25*(math.exp(-((t-.12)/.025)**2)+math.exp(-((t-.45)/.025)**2))
        data.append(struct.pack('<h',int(max(-1,min(1,v))*20000)))
    with wave.open(str(root/(name+'.wav')),'wb') as out:out.setparams((1,2,rate,len(data),'NONE','not compressed'));out.writeframes(b''.join(data))
print('Created original synthesized engine, tire, harbor, shot, reload and step sounds')
