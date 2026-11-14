"""Curated CC0-derived male NPCs with authored face edits and rigged outfit geometry.
Preserves existing skeleton/actions/morphs; not independently scanned humans.
Run after add_facial_controls.py. Source hero remains unchanged.
"""
import sys,math,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
PROFILES=[
 ('worker','hardhat',(.82,.30,.035),(.82,.60,.12),1.07,.010,.55),
 ('supervisor','whitehat',(.33,.39,.39),(.9,.9,.84),.94,-.004,.35),
 ('security','helmet',(.055,.085,.15),(.055,.07,.10),1.08,.008,.05),
 ('pedestrian','beanie',(.30,.20,.12),(.32,.12,.08),.93,-.008,.20),
 ('delivery','cap',(.10,.26,.18),(.10,.27,.16),.97,.004,.15),
 ('dante','mechanic',(.18,.23,.26),(.22,.22,.20),1.09,.012,.7),
 ('police','policecap',(.045,.09,.19),(.04,.07,.14),1.03,-.003,.05),
 ('faction','hood',(.075,.075,.08),(.055,.055,.06),.94,.009,.15),
 ('shopkeeper','apron',(.32,.30,.22),(.57,.47,.31),1.02,-.006,.8)]
report=[]
for identity,style,color,hat_color,width,nose,gray in PROFILES:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/adrian.blend'))
 arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 arm.animation_data.action=None
 for bone in arm.pose.bones:bone.matrix_basis=Matrix.Identity(4)
 body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 # Apply the same rest-space sculpt to Basis and all facial morphs.
 keys=body.data.shape_keys.key_blocks if body.data.shape_keys else []
 for key in keys:
  for vertex in key.data:
   p=body.matrix_world@vertex.co
   if p.z>1.49:
    influence=min(1,(p.z-1.49)/.08)
    p.x*=1+(width-1)*influence
    if p.y<-.075 and 1.57<p.z<1.65:p.y-=nose*math.exp(-((p.x/.025)**2))
    if p.z>1.70:p.z=1.70+(p.z-1.70)*(.22 if style in ['whitehat','mechanic','policecap'] else .58)
   vertex.co=body.matrix_world.inverted()@p
 for i,m in enumerate(list(body.data.materials)):
  n=m.copy();n.name=identity+' / '+m.name;body.data.materials[i]=n
  bs=n.node_tree.nodes.get('Principled BSDF')
  tex=next((node for node in n.node_tree.nodes if node.type=='TEX_IMAGE'),None)
  if tex and i==0:
   bw=n.node_tree.nodes.new('ShaderNodeRGBToBW');n.node_tree.links.new(tex.outputs['Color'],bw.inputs[0])
   wash=n.node_tree.nodes.new('ShaderNodeMapRange');wash.inputs['From Min'].default_value=0;wash.inputs['From Max'].default_value=1;wash.inputs['To Min'].default_value=.50;wash.inputs['To Max'].default_value=1
   n.node_tree.links.new(bw.outputs[0],wash.inputs[0])
   mul=n.node_tree.nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[1].default_value=(*color,1)
   n.node_tree.links.new(wash.outputs[0],mul.inputs[2]);n.node_tree.links.new(mul.outputs[0],bs.inputs['Base Color'])
  elif i==2:
   bs.inputs['Base Color'].default_value=(.06+gray*.22,.045+gray*.20,.035+gray*.19,1)
   for link in list(n.node_tree.links):
    if link.to_socket==bs.inputs['Base Color']:n.node_tree.links.remove(link)
 # Export supports vertex-color/standard materials, so bake the clothing wash to an image.
 source=next(node.image for node in body.data.materials[0].node_tree.nodes if node.type=='TEX_IMAGE')
 import numpy as np
 pixels=np.array(source.pixels[:],dtype=np.float32).reshape(-1,4)
 lum=pixels[:,:3]@np.array([.2126,.7152,.0722]);pixels[:,:3]=(0.5+lum[:,None]*.5)*np.array(color)
 cloth=bpy.data.images.new(identity+'_outfit',width=source.size[0],height=source.size[1]);cloth.pixels.foreach_set(pixels.ravel());cloth.pack()
 mat=body.data.materials[0];bs=mat.node_tree.nodes.get('Principled BSDF');tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=cloth;mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
 clothmat=material(identity+' tailored accessories',color,rough=.78)
 dark=material(identity+' leather and nylon',(.035,.04,.045),rough=.65)
 metal=material(identity+' fittings',(.35,.38,.39),.75,.3)
 hat=material(identity+' headwear',hat_color,rough=.65)
 def bind(o,bone='Head'):
  world=o.matrix_world.copy();o.parent=arm;o.matrix_world=world
  group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1,'REPLACE')
  modifier=o.modifiers.new('Rig attachment','ARMATURE');modifier.object=arm
  return o
 # Curved shell, rather than a rectangular hat proxy.
 if style in ['hardhat','whitehat','helmet','beanie','cap','policecap']:
  verts=[];faces=[]
  for ring in range(7):
   theta=ring*math.pi/2/6
   for j in range(24):
    angle=j*math.tau/24;verts.append((math.cos(angle)*.101*math.sin(theta),-.005+math.sin(angle)*.105*math.sin(theta),1.735+.073*math.cos(theta)))
  for ring in range(6):
   for j in range(24):faces.append((ring*24+j,ring*24+(j+1)%24,(ring+1)*24+(j+1)%24,(ring+1)*24+j))
  bind(mesh(identity+' shaped headwear',verts,faces,hat))
  if style in ['hardhat','whitehat']:
   bpy.ops.mesh.primitive_torus_add(major_radius=.11,minor_radius=.008,major_segments=32,minor_segments=8,location=(0,-.005,1.735));bind(finish(bpy.context.object,hat))
  elif style in ['cap','policecap']:
   bind(box(identity+' cap visor',(0,-.12,1.735),(.18,.12,.012),hat,.015))
 if style in ['hardhat','whitehat','helmet']:
  # Sewn high-vis or security vest, shoulder straps, front pockets, reflective bands.
  for side in [-1,1]:
   bind(box(identity+' vest front',(side*.105,-.115,1.26),(.17,.045,.37),clothmat,.025),'Spine')
   bind(box(identity+' reflective band',(side*.105,-.141,1.21),(.165,.008,.025),metal,.003),'Spine')
   bind(box(identity+' chest pocket',(side*.105,-.147,1.35),(.11,.025,.085),dark,.009),'Spine')
 elif style=='mechanic':
  for side in [-1,1]:
   bind(box('Dante overall strap',(side*.09,-.115,1.30),(.052,.027,.35),dark,.01),'Spine')
  bind(box('Dante bib',(0,-.14,1.21),(.24,.036,.22),dark,.025),'Spine')
 elif style in ['apron','delivery']:
  bind(box(identity+' apron bib',(0,-.13,1.25),(.27,.028,.30),hat,.02),'Spine')
  bind(box(identity+' apron skirt',(0,-.115,.98),(.38,.028,.26),hat,.025),'Hips')
 if style in ['mechanic','whitehat','apron']:
  for side in [-1,1]:
   bind(box(identity+' glasses lens',(side*.037,-.117,1.659),(.056,.014,.025),dark,.006))
  bind(beam('Glasses bridge',(-.012,-.12,1.66),(.012,-.12,1.66),.003,metal))
 if style=='hood':
  for side in [-1,1]:bind(box('Hood cowl',(side*.09,.045,1.65),(.038,.09,.21),hat,.018))
  bind(box('Hood crown',(0,.03,1.758),(.18,.09,.026),hat,.02))
 if style in ['delivery','whitehat']:
  bind(box(identity+' shoulder satchel',(.23,.035,1.02),(.18,.10,.24),dark,.025),'Hips')
 for side in [-1,1]:bind(box(identity+' belt pouch',(side*.16,.02,1.02),(.09,.075,.12),dark,.015),'Hips')
 if style=='policecap':bind(box('Officer chest badge',(-.09,-.127,1.38),(.032,.008,.045),metal,.007),'Spine')
 export('characters/npc_'+identity+'.glb')
 report.append({'id':identity,'style':style,'face_width_factor':width,'nose_sculpt_m':nose,'hair_gray':gray,'source':'existing CC0 rigged human; original curated sculpt/outfit additions','bounds':'same skeleton/rest height; no random body stretching'})
(ROOT/'art/source/npc-variants.json').write_text(json.dumps(report,indent=2))
print('CURATED_NPC_VARIANTS',len(report))
