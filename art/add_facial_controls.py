"""Conservative authored facial deformation on existing CC0 hero topology.
Lower-fidelity jaw/chin motion and lid closure; no phoneme/eye rig claim.
Run after refine_realism.py. Idempotent; preserves skeleton/actions/secondary weights.
"""
import sys,math,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/adrian.blend'))
body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
if body.data.shape_keys: body.shape_key_clear()
body.shape_key_add(name='Basis')
counts={}
for name in ['JawOpen','BlinkLeft','BlinkRight','BrowConcern']:
 key=body.shape_key_add(name=name);count=0
 for v,dst in zip(body.data.vertices,key.data):
  p=body.matrix_world@v.co;x,y,z=p
  shift=Vector()
  face=max(0,min(1,(-y-.065)/.025))
  if name=='JawOpen':
   weight=math.exp(-((x/.060)**4))*max(0,min(1,(1.584-z)/.020))*max(0,min(1,(z-1.49)/.025))*face
   shift=Vector((0,.003*weight,-.014*weight))
  elif name.startswith('Blink'):
   eye=-.033 if name=='BlinkLeft' else .033
   weight=math.exp(-((x-eye)/.020)**4-((z-1.654)/.016)**4)*face
   shift=Vector((0,-.002*weight,(1.653-z)*weight*.95))
  else:
   weight=math.exp(-((abs(x)-.028)/.025)**4-((z-1.684)/.016)**4)*face
   shift=Vector((0,0,.004*weight))
  if shift.length>.00001:count+=1
  dst.co=body.matrix_world.inverted()@(p+shift)
 counts[name]=count
 key.value=0
assert min(counts.values())>10,counts
export('characters/adrian.glb',True)
(ROOT/'art/source/facial-controls.json').write_text(json.dumps({'method':'limited geometric facial morphs; no oral cavity, eyeball rotation or visemes','affected_vertices':counts},indent=2))
print('FACIAL_CONTROLS',counts)
