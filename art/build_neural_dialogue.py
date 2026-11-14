"""Offline neural dialogue generation; runtime ships WAV only, no model/API.
Kokoro-82M Apache-2.0 / kokoro-onnx MIT. Use isolated tools/voice-tools environment.
"""
import os,sys
os.environ['OMP_NUM_THREADS']='4'
from pathlib import Path
import json,hashlib
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
r=Path(__file__).resolve().parents[1]
k=Kokoro(str(r/'tools/voice-tools/kokoro/kokoro-v1.0.int8.onnx'),str(r/'tools/voice-tools/kokoro/voices-v1.0.bin'))
profiles={
 'Adrian':{'voice':'am_michael','speed':.98,'direction':'Direct, restrained concern'},
 'Dante':{'voice':'bm_george','speed':.94,'direction':'Measured mechanic, protective'},
 'Mara':{'voice':'af_sarah','speed':1.02,'direction':'Precise investigative urgency'},
 'Elena':{'voice':'bf_emma','speed':1.03,'direction':'Clear and skeptical'},
 'Victor':{'voice':'bm_daniel','speed':.92,'direction':'Controlled authority'},
 'Nadia':{'voice':'af_nicole','speed':1.02,'direction':'Firm and conversational'},
 'Elias':{'voice':'bm_lewis','speed':.98,'direction':'Deliberate investigator'},
 'Marcus':{'voice':'am_onyx','speed':.95,'direction':'Terse and guarded'}}

def synth(text,person,path):
 profile=profiles[person]
 samples,rate=k.create(text,voice=profile['voice'],speed=profile['speed'],lang='en-gb' if profile['voice'].startswith('b') else 'en-us',sentence_pause=.28,clause_pause=.12)
 assert len(samples)>rate*.3
 rms=float(np.sqrt(np.mean(samples*samples)));gain=min(.89/max(.001,float(np.max(np.abs(samples)))),.11/max(.001,rms))
 samples=np.clip(samples*gain,-.89,.89)
 sf.write(str(path),samples,rate,subtype='PCM_16')
 hop=rate//50
 envelope=[float(np.sqrt(np.mean(samples[i:i+hop]**2))) for i in range(0,len(samples),hop)]
 scale=max(envelope)
 return {'duration':len(samples)/rate,'envelope_hz':50,'envelope':[round(min(1,v/max(.001,scale)*1.3),4) for v in envelope],'voice':profile['voice'],'peak':float(np.max(np.abs(samples))),'rms':float(np.sqrt(np.mean(samples*samples))),'sample_rate':rate}

p=r/'data/dialogue.json';dialogue=json.loads(p.read_text())
for line in dialogue['lines']:
 line.setdefault('audio','res://assets/audio/dialogue/'+line['id']+'.wav')
 path=r/line['audio'].removeprefix('res://')
 if '--regenerate' not in sys.argv and path.exists() and 'peak' in line: continue
 line.update(synth(line['line'],line.get('voice_profile',line['speaker']),path));print('NEURAL_LINE',line['id'],flush=True)
dialogue['quality']='Offline Kokoro neural voices; amplitude jaw fallback remains, not viseme lip sync'
dialogue['tool']='kokoro-onnx 0.6.1, Kokoro-82M v1.0 int8; generation only'
p.write_text(json.dumps(dialogue,indent=2)+'\n')
folder=r/'assets/audio/voice_profiles';folder.mkdir(exist_ok=True)
texts={'Adrian':'Mara trusted this contact. I need to know why he vanished.','Dante':'You are looking for answers. Just promise me you will come back.','Mara':'Check the transport manifest. The numbers do not match the cargo.','Elena':'A missing name is a lead, Adrian. It is not proof.','Victor':'This city survives because someone is willing to make the difficult decisions.','Nadia':'People here remember who stood beside them when it mattered.','Elias':'Tell me exactly what you saw. Start with the truck.','Marcus':'The harbor is a restricted site. Leave the evidence where you found it.'}
for person,profile in profiles.items():
 if '--regenerate' not in sys.argv and (r/'data/voice_profiles.json').exists():
  previous=json.loads((r/'data/voice_profiles.json').read_text())['profiles'].get(person,{})
  if previous and (folder/(person.lower()+'.wav')).exists():
   profile.update(previous);continue
 path=folder/(person.lower()+'.wav');profile['sample_audio']='res://'+path.relative_to(r).as_posix();profile['sample_text']=texts[person];profile.update(synth(texts[person],person,path));print('VOICE_PROFILE',person,flush=True)
(r/'data/voice_profiles.json').write_text(json.dumps({'generator':'Kokoro-82M v1.0, Apache-2.0. Generic licensed model voice presets, no requested impersonation or cloning.','profiles':profiles},indent=2)+'\n')
print('NEURAL_AUDIO_COMPLETE',flush=True)
