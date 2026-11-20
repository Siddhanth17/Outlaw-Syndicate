"""Assign existing resident IDs to connected west/east sidewalks; preserve all identities/voices."""
from pathlib import Path
import json
p=Path(__file__).resolve().parents[1]/'data/living_roster.json'
d=json.loads(p.read_text(encoding='utf-8'))
ids={int(r['id'].split('_')[-1]):r for r in d['citizens']}
for group,x in [([2,4,6,8,12,14,16],-130),([3,5,7,9,11,13,15,17],132)]:
    for j,i in enumerate(group):
        r=ids[i];z=80+j*16
        r['home']=[x,.2,z];r['work']=[x,.2,z+20];r['rest']=[x,.2,z+8]
p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8')
