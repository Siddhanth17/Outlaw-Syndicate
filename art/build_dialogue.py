"""Offline draft voices using upstream eSpeak NG formant synthesis.
Tool is build-time only, not distributed. Original text, no recorded voice cloning.
"""
from pathlib import Path
import subprocess,wave,array,math,json,hashlib
r=Path(__file__).resolve().parents[1];tool=r/'tools/voice-tools/extracted/eSpeak NG/espeak-ng.exe'
lines=[
 {'id':'greeting_adrian','speaker':'Adrian','line':'Dante. Mara sent me one message. Then she disappeared.','gesture':'concern'},
 {'id':'greeting_dante','speaker':'Dante','line':'She left her car here. The ledger is in warehouse nine.','gesture':'point'},
 {'id':'question_adrian','speaker':'Adrian','line':'Who else knows about it?','gesture':'open'},
 {'id':'warning_dante','speaker':'Dante','line':'Someone with money. Take the car. Keep your head down.','gesture':'warning'},
 {'id':'closing_dante','speaker':'Dante','line':"I will hide the car. You find Elena. Whatever Mara found, we finish it together.",'gesture':'open'},
 {'id':'closing_adrian','speaker':'Adrian','line':'We find Mara first. Then we make them answer.','gesture':'nod'}]
output=r/'assets/audio/dialogue';output.mkdir(exist_ok=True)
for line in lines:
 voice='en-us+m3' if line['speaker']=='Adrian' else 'en-gb+m1'
 path=output/(line['id']+'.wav')
 subprocess.run([str(tool),'--path='+str(tool.parent),'-v',voice,'-s','155','-p','42' if line['speaker']=='Adrian' else '33','-w',str(path),line['line']],cwd=tool.parent,check=True)
 with wave.open(str(path)) as w:
  rate=w.getframerate();pcm=array.array('h',w.readframes(w.getnframes()));duration=len(pcm)/rate
 hop=rate//50;rms=[math.sqrt(sum((s/32768)**2 for s in pcm[i:i+hop])/max(1,len(pcm[i:i+hop]))) for i in range(0,len(pcm),hop)]
 peak=max(rms);line.update({'audio':'res://assets/audio/dialogue/'+path.name,'duration':duration,'envelope_hz':50,'envelope':[round(min(1,v/peak*1.4),4) for v in rms],'voice':voice})
(r/'data/dialogue.json').write_text(json.dumps({'quality':'draft formant synthetic voices; amplitude-driven jaw fallback, not phoneme lip sync','tool':'eSpeak NG 1.52.0, build-time only','lines':lines},indent=2)+'\n')
print('Generated',len(lines),'original-text draft dialogue clips')
