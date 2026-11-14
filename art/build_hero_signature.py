"""Signature Adrian derivative; original base/NPCs/WAVs are preserved.
Fitted mesh jacket, original procedural leather and layered skinned hair ribbons.
Early-production art; not a photoreal face/hair or collision-complete cloth claim.
"""
import sys,math,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
import bmesh,numpy as np
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/adrian.blend'))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
arm.animation_data.action=None
for bone in arm.pose.bones:bone.matrix_basis=Matrix.Identity(4)
body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
# Conservative radial muscle/chest sculpt; original joint locations unchanged.
for key in body.data.shape_keys.key_blocks:
 for vertex in key.data:
  p=body.matrix_world@vertex.co;x,y,z=p
  if .99<z<1.45:
   t=math.sin((z-.99)/.46*math.pi)
   if abs(x)<.24:
    p.x*=1+.055*t
    p.y+=(-1 if y<0 else 1)*.009*t
  if z>1.70:p.z=1.70+(z-1.70)*.35
  vertex.co=body.matrix_world.inverted()@p
# Dark fitted under-layer, not the jacket itself.
shirt=material('Adrian charcoal underlayer',(.025,.028,.03),rough=.86)
body.data.materials[0]=shirt
for poly in body.data.polygons:
 center=sum((body.matrix_world@body.data.vertices[v].co for v in poly.vertices),Vector())/len(poly.vertices)
 if center.z<1.50 and abs(center.x)<.29:poly.material_index=0
# Original leather micrograin maps.
rng=np.random.default_rng(93);size=512;grain=rng.normal(0,1,(size,size))
albedo=np.zeros((size,size,4),dtype=np.float32);albedo[:,:,:3]=np.clip(.024+grain[:,:,None]*.002,0,1);albedo[:,:,3]=1
rough=np.clip(.48+grain*.035,.35,.65)
images=[]
for name,values in [('hero_leather_albedo',albedo),('hero_leather_roughness',np.dstack([rough,rough,rough,np.ones_like(rough)]))]:
 image=bpy.data.images.new(name,width=size,height=size);image.pixels.foreach_set(values.astype(np.float32).ravel());image.filepath_raw=str(ROOT/'assets/textures'/(name+'.png'));image.file_format='PNG';image.save();images.append(image)
leather=material('Adrian / grained charcoal leather',(.025,.025,.027),rough=.48)
bs=leather.node_tree.nodes.get('Principled BSDF');bs.inputs['Coat Weight'].default_value=.12;bs.inputs['Coat Roughness'].default_value=.35
for image,socket in zip(images,['Base Color','Roughness']):
 if socket=='Roughness': image.colorspace_settings.name='Non-Color'
 tex=leather.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;leather.node_tree.links.new(tex.outputs['Color'],bs.inputs[socket])
# Duplicate only garment faces, preserving deform weights and UVs.
jacket=body.copy();jacket.data=body.data.copy();bpy.context.collection.objects.link(jacket);jacket.name='Adrian fitted leather jacket'
jacket.shape_key_clear()
bm=bmesh.new();bm.from_mesh(jacket.data)
remove=[]
for face in bm.faces:
 center=sum((jacket.matrix_world@v.co for v in face.verts),Vector())/len(face.verts)
 x,y,z=center
 keep=(.96<z<1.46 and abs(x)<.26) or (1.08<z<1.48 and .23<abs(x)<.62)
 if not keep:remove.append(face)
bmesh.ops.delete(bm,geom=remove,context='FACES')
loose=[v for v in bm.verts if not v.link_faces]
if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
bm.to_mesh(jacket.data);bm.free();jacket.data.materials.clear();jacket.data.materials.append(leather)
for poly in jacket.data.polygons:poly.material_index=0
for v in jacket.data.vertices:v.co+=v.normal*.004
solid=jacket.modifiers.new('Real garment edge thickness','SOLIDIFY');solid.thickness=.006;solid.offset=1
# Accessories bind to the existing compatible skeleton.
def bind(obj,bone):
 world=obj.matrix_world.copy();obj.parent=arm;obj.matrix_world=world
 obj.vertex_groups.clear();group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
 mod=obj.modifiers.new('Anatomical attachment','ARMATURE');mod.object=arm
 return obj
metal=material('Adrian blackened zipper hardware',(.19,.20,.21),.8,.28)
stitch=material('Adrian muted jacket stitching',(.10,.10,.09),rough=.85)
for side in [-1,1]:
 bind(mesh('Sculpted leather lapel',[(side*.015,-.16,1.34),(side*.11,-.14,1.45),(side*.08,-.10,1.48)],[(0,1,2)],leather),'Spine2')
 bind(beam('Jacket pocket welt',(side*.06,-.155,1.16),(side*.19,-.14,1.21),.004,leather),'Spine')
 bind(beam('Pocket stitching',(side*.06,-.160,1.16),(side*.19,-.145,1.21),.0012,stitch),'Spine')
 bind(beam('Shoulder seam',(side*.12,.01,1.44),(side*.25,.02,1.40),.002,stitch),'Spine2')
for i in range(25):bind(box('Zipper tooth',(0,-.158,1.03+i*.014),(.012,.007,.004),metal,.001),'Spine')
bind(box('Zipper pull',(0,-.17,1.37),(.014,.008,.026),metal,.003),'Spine')
# Four long, downward chains added without renaming original secondary bones.
bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
chains={}
for side in [-1,1]:
 for kind in ['Back','Side']:
  name='LongHair'+kind+('L' if side<0 else 'R')
  a=(side*7,6,172) if kind=='Back' else (side*10,-4,170)
  b=(side*10,13,156) if kind=='Back' else (side*13,-13,154)
  c=(side*12,18,139) if kind=='Back' else (side*16,-18,139)
  if name not in arm.data.edit_bones:
   bone=arm.data.edit_bones.new(name);bone.head=a;bone.tail=b;bone.parent=arm.data.edit_bones['Head']
   tip=arm.data.edit_bones.new(name+'Tip');tip.head=b;tip.tail=c;tip.parent=bone;tip.use_connect=True
  chains[(side,kind)]=name
bpy.ops.object.mode_set(mode='OBJECT')
# Original alpha strand map with grouped highlights and tapered tips.
w,h=128,512;yy,xx=np.mgrid[0:h,0:w];strand=.5+.5*np.sin(xx*.75+np.sin(xx*.13)*2)
alpha=np.clip((np.sin(np.pi*xx/(w-1))**.7)*np.minimum(1,yy/(h*.22))*(.15+.85*np.clip((strand-.35)/.45,0,1)),0,1)
texture=np.zeros((h,w,4),dtype=np.float32);texture[:,:,:3]=(.018+strand[:,:,None]*.023)*np.array([1,.78,.60]);texture[:,:,3]=alpha
image=bpy.data.images.new('hero_long_hair_strands',width=w,height=h,alpha=True);image.pixels.foreach_set(texture.ravel());image.filepath_raw=str(ROOT/'assets/textures/hero_long_hair_strands.png');image.file_format='PNG';image.save()
hair=material('Adrian / layered dark hair cards',(.03,.023,.018),rough=.32);hair.surface_render_method='DITHERED';hair.use_backface_culling=False
bs=hair.node_tree.nodes.get('Principled BSDF');tex=hair.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;hair.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);hair.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Alpha'])
card_count=0
for side in [-1,1]:
 for kind in ['Back','Side']:
  for layer in range(9):
   spread=(layer-4)*.009
   points=[]
   for j in range(9):
    t=j/8;z=1.73-t*(.32+(layer%3)*.008)
    if kind=='Back':x=side*(.045+.07*t)+spread;y=.055+.13*t+math.sin(t*math.pi)*.025
    else:x=side*(.102+.045*t);y=-.02-.14*t+spread
    points.append(Vector((x,y,z)))
   verts=[];faces=[]
   for point in points:
    width=.016 if kind=='Back' else .011
    axis=Vector((width/2,0,0)) if kind=='Back' else Vector((0,width/2,0))
    verts.extend([point-axis,point+axis])
   for j in range(8):faces.append((j*2,j*2+1,j*2+3,j*2+2))
   obj=mesh('Layered hair ribbon',verts,faces,hair);world=obj.matrix_world.copy();obj.parent=arm;obj.matrix_world=world
   uv=obj.data.uv_layers.new(name='Strands')
   for loop in obj.data.loops:
    idx=loop.vertex_index;uv.data[loop.index].uv=(idx%2,1-(idx//2)/8)
   root=obj.vertex_groups.new(name=chains[(side,kind)]);tip=obj.vertex_groups.new(name=chains[(side,kind)]+'Tip')
   for v in obj.data.vertices:
    t=(v.index//2)/8;amount=max(0,min(1,(t-.3)/.7));root.add([v.index],1-amount,'REPLACE');tip.add([v.index],amount,'REPLACE')
   mod=obj.modifiers.new('Skinned spring chain','ARMATURE');mod.object=arm;card_count+=1
# Smooth layered under-volume prevents translucent cards from reading as flat panels.
volume_mat=material('Adrian / dark flowing hair under-volume',(.023,.016,.012),rough=.38)
tex=volume_mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
volume_mat.node_tree.links.new(tex.outputs['Color'],volume_mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
levels=[(1.795,.012,.015),(1.77,.065,.07),(1.72,.105,.105),(1.64,.116,.12),(1.55,.13,.14),(1.47,.17,.17),(1.40,.245,.19)]
segments=48;verts=[];faces=[]
for row,(z,rx,ry) in enumerate(levels):
 for j in range(segments+1):
  phi=-math.pi/2+.60+(math.tau-1.20)*j/segments
  ripple=1+.012*math.sin(j*2.3+row*.5)
  verts.append((math.cos(phi)*rx*ripple,math.sin(phi)*ry*ripple,z-(.01*math.sin(j*1.7)**2 if row==len(levels)-1 else 0)))
for row in range(len(levels)-1):
 for j in range(segments):
  a=row*(segments+1)+j;b=a+segments+1;faces.append((a,a+1,b+1,b))
volume=mesh('Adrian layered long hair volume',verts,faces,volume_mat)
for poly in volume.data.polygons:poly.use_smooth=True
world=volume.matrix_world.copy();volume.parent=arm;volume.matrix_world=world
head=volume.vertex_groups.new(name='Head')
groups={name:volume.vertex_groups.new(name=name) for name in [v for name in chains.values() for v in [name,name+'Tip']]}
for v in volume.data.vertices:
 row=v.index//(segments+1);z=levels[row][0]
 x,y,_=v.co;side=-1 if x<0 else 1;kind='Side' if y<0 else 'Back';name=chains[(side,kind)]
 weight=max(0,min(1,(1.72-z)/.25));tip=max(0,min(.8,(1.56-z)/.19))
 head.add([v.index],1-weight,'REPLACE');groups[name].add([v.index],weight*(1-tip),'REPLACE');groups[name+'Tip'].add([v.index],weight*tip,'REPLACE')
mod=volume.modifiers.new('Long hair spring skin','ARMATURE');mod.object=arm
uv=volume.data.uv_layers.new(name='Strands')
for loop in volume.data.loops:
 index=loop.vertex_index;uv.data[loop.index].uv=((index%(segments+1))/segments*2,1-(index//(segments+1))/(len(levels)-1))

# Join same-material rig attachments to bound draw calls; preserve garment/body morphs.
groups={}
for obj in list(bpy.context.scene.objects):
 if obj.type=='MESH' and obj not in [body,jacket]:groups.setdefault(obj.active_material.name,[]).append(obj)
for objects in groups.values():
 bpy.ops.object.select_all(action='DESELECT')
 for obj in objects:obj.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 if len(objects)>1:bpy.ops.object.join()
# Keep hero action library, secondary weights and facial controls intact.
export('characters/adrian_signature.glb',True)
(ROOT/'art/source/hero-signature.json').write_text(json.dumps({'source':'existing CC0 hero derivative; original jacket, maps, ribbons and hardware','hair_cards':card_count,'long_hair_chains':list(chains.values()),'max_torso_width_change':.055,'oral_cavity':False,'fingers':'existing coarse topology/rig retained','collision_complete_cloth':False},indent=2))
print('HERO_SIGNATURE_CREATED',card_count)
