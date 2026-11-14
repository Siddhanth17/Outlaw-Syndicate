"""Separate half-tied hero derivative, guided by the user reference.

The reference image is never copied into output assets. Existing hero/NPCs remain.
Conservative topology sculpt, original swept ribbons; not a scanned face or groom.
"""
import sys, math, json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
import numpy as np

bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/adrian_signature.blend'))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
arm.animation_data.action=None
for bone in arm.pose.bones: bone.matrix_basis=Matrix.Identity(4)
for obj in list(bpy.context.scene.objects):
    if obj.type=='MESH' and obj.active_material and 'hair' in obj.active_material.name.lower():
        bpy.data.objects.remove(obj,do_unlink=True)
body=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.shape_keys)
# Small anatomical changes applied identically to all facial shape keys.
for key in body.data.shape_keys.key_blocks:
    for v in key.data:
        p=body.matrix_world@v.co; x,y,z=p
        if 1.52<z<1.68 and abs(x)<.12:
            jaw=math.exp(-((z-1.565)/.035)**2)
            p.x*=1+.055*jaw
            if y<-.035:p.y-=.004*jaw
        if 1.03<z<1.46 and .10<abs(x)<.56:
            p.x*=1+.025*math.sin((z-1.03)/.43*math.pi)
        v.co=body.matrix_world.inverted()@p
# Apply matching limited silhouette adjustment to actual garment.
for obj in bpy.context.scene.objects:
    if obj.type=='MESH' and 'fitted leather jacket' in obj.name:
        for v in obj.data.vertices:
            p=obj.matrix_world@v.co
            if 1.03<p.z<1.46 and .1<abs(p.x)<.56:p.x*=1+.025*math.sin((p.z-1.03)/.43*math.pi)
            v.co=obj.matrix_world.inverted()@p

w,h=128,512; yy,xx=np.mgrid[0:h,0:w]
strand=.5+.5*np.sin(xx*1.55+.4*np.sin(xx*.21))
rgba=np.zeros((h,w,4),dtype=np.float32)
rgba[:,:,:3]=(.013+strand[:,:,None]*.019)*np.array([1,.79,.67])
rgba[:,:,3]=np.clip(np.sin(np.pi*xx/(w-1))**.4,0,1)*np.clip(yy/(h*.10),0,1)
image=bpy.data.images.new('adrian_swept_strands',width=w,height=h,alpha=True)
image.pixels.foreach_set(rgba.ravel()); image.filepath_raw=str(ROOT/'assets/textures/adrian_swept_strands.png');image.file_format='PNG';image.save()
hair=material('Adrian half-tied / dark strand ribbons',(.022,.017,.014),rough=.57)
hair.surface_render_method='DITHERED';hair.use_backface_culling=False
bs=hair.node_tree.nodes.get('Principled BSDF');bs.inputs['Specular IOR Level'].default_value=.24
tex=hair.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
hair.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);hair.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Alpha'])
capmat=material('Adrian swept crown / matte base',(.019,.014,.012),rough=.66)
capmat.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value=.22
captex=capmat.node_tree.nodes.new('ShaderNodeTexImage');captex.image=image
capmat.node_tree.links.new(captex.outputs['Color'],capmat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])

def skin(obj, group='Head', tip=None):
    world=obj.matrix_world.copy();obj.parent=arm;obj.matrix_world=world
    a=obj.vertex_groups.new(name=group)
    b=obj.vertex_groups.new(name=tip) if tip else None
    for v in obj.data.vertices:
        t=max(0,min(.85,(1.64-v.co.z)/.23)) if b else 0
        a.add([v.index],1-t,'REPLACE')
        if b:b.add([v.index],t,'REPLACE')
    mod=obj.modifiers.new('Bounded secondary hair rig','ARMATURE');mod.object=arm
    return obj

# Rounded scalp/crown only; no broad cone down to the shoulders.
verts=[];faces=[];rows=8;segments=48
for row in range(rows):
    for j in range(segments+1):
        phi=-math.pi/2+math.tau*j/segments
        end_angle=1.35 if math.sin(phi)<-.25 else (2.12 if math.sin(phi)>.25 else 1.78)
        theta=.05+(end_angle-.05)*row/(rows-1)
        x=math.sin(theta)*math.cos(phi)*.098
        y=.012+math.sin(theta)*math.sin(phi)*.106
        z=1.685+math.cos(theta)*.098
        # Expose front hairline rather than draping over the face.
        if y<-.045:z+=.015*row/(rows-1)
        verts.append((x,y,z))
for row in range(rows-1):
    for j in range(segments):
        a=row*(segments+1)+j;b=a+segments+1;faces.append((a,a+1,b+1,b))
cap=mesh('Half-tied rounded crown',verts,faces,capmat);skin(cap)
for f in cap.data.polygons:f.use_smooth=True
uv=cap.data.uv_layers.new(name='Swept scalp flow')
for loop in cap.data.loops:
    idx=loop.vertex_index;uv.data[loop.index].uv=((idx%(segments+1))/segments*3,1-(idx//(segments+1))/(rows-1))
# Small opaque wavy locks fill the tail without a broad shoulder-sized shell.
for strand_index in range(14):
    angle=strand_index*2.39996;spread=.012+.032*(strand_index%5)/4
    vertices=[];polygons=[];nr=12;ns=10
    for row in range(nr):
        t=row/(nr-1);radius=.010*(.35+.65*math.sin(math.pi*t))
        center=Vector((math.cos(angle)*spread*(.4+t)+.004*math.sin(t*7+angle),.121+.049*t+math.sin(angle)*spread*.5,1.685-(.245+(strand_index%4)*.009)*t))
        for j in range(ns):
            a=j*math.tau/ns;vertices.append(center+Vector((math.cos(a)*radius,math.sin(a)*radius,0)))
    for row in range(nr-1):
        for j in range(ns):
            a=row*ns+j;b=row*ns+(j+1)%ns;polygons.append((a,b,b+ns,a+ns))
    lock=mesh('Half-tail curved strand group',vertices,polygons,capmat)
    for f in lock.data.polygons:f.use_smooth=True
    skin(lock,'LongHairBackL' if math.cos(angle)<0 else 'LongHairBackR', 'LongHairBackLTip' if math.cos(angle)<0 else 'LongHairBackRTip')
    uv=lock.data.uv_layers.new(name='Lock strand flow')
    for loop in lock.data.loops:
        idx=loop.vertex_index;uv.data[loop.index].uv=((idx%ns)/ns,1-(idx//ns)/(nr-1))

def ribbon(name, points, width, axis, bone='Head', tip=None):
    verts=[];faces=[]
    for j,p in enumerate(points):
        t=j/(len(points)-1);offset=Vector(axis)*width*.5*(.25+.75*math.sin(math.pi*(.08+.9*t)))
        verts.extend([Vector(p)-offset,Vector(p)+offset])
    for j in range(len(points)-1):faces.append((j*2,j*2+1,j*2+3,j*2+2))
    obj=mesh(name,verts,faces,hair);uv=obj.data.uv_layers.new(name='Flow')
    for loop in obj.data.loops:
        idx=loop.vertex_index;uv.data[loop.index].uv=(idx%2,1-(idx//2)/(len(points)-1))
    for f in obj.data.polygons:f.use_smooth=True
    skin(obj,bone,tip)

for i in range(64):
    u=(i/63-.5)*2;points=[]
    for j in range(13):
        t=j/12
        x=u*.083*(1-t*.83)
        y=-.068+.179*t
        z=1.744+.048*math.sin(math.pi*t)-.053*t+.002*math.sin(i*1.7)
        points.append((x,y,z))
    ribbon('Swept crown strand',points,.007,(1,0,0))
for i in range(72):
    angle=i*2.39996;radius=.008+.039*(i%9)/8;side='L' if math.cos(angle)<0 else 'R';points=[]
    for j in range(16):
        t=j/15
        x=math.cos(angle)*radius*(.45+1.1*t)+.009*math.sin(t*8+i*.7)*t
        y=.112+.055*t+.012*math.sin(t*6+i*.5)
        z=1.69-(.24+(i%7)*.008)*t
        points.append((x,y,z))
    ribbon('Gathered half-tail layer',points,.008,(math.cos(angle),math.sin(angle),0),'LongHairBack'+side,'LongHairBack'+side+'Tip')
for side in [-1,1]:
    suffix='L' if side<0 else 'R'
    for i in range(20):
        points=[]
        for j in range(14):
            t=j/13
            points.append((side*(.088+.018*t+.005*math.sin(t*7+i)),.006+i*.003+.045*t,1.713-(.24+(i%4)*.013)*t))
        ribbon('Loose temple and shoulder layer',points,.006,(0,1,0),'LongHairSide'+suffix,'LongHairSide'+suffix+'Tip')
tie=material('Half-tie dark leather band',(.014,.012,.01),rough=.8)
bpy.ops.mesh.primitive_torus_add(major_radius=.024,minor_radius=.004,major_segments=24,minor_segments=8,location=(0,.112,1.678))
finish(bpy.context.object,tie);skin(bpy.context.object)
# Join identical materials, keep all original face morphs and compatible actions.
groups={}
for o in list(bpy.context.scene.objects):
    if o.type=='MESH' and o!=body and not o.data.shape_keys:groups.setdefault(o.active_material.name if o.active_material else '',[]).append(o)
for objects in groups.values():
    if len(objects)<2:continue
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
# Separate motorcycle pose: straddled knees, feet near pegs, hands at handlebar height.
source_action=bpy.data.actions.get('Drive')
if source_action:
    arm.animation_data.action=source_action;bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
    base={b.name:b.matrix_basis.copy() for b in arm.pose.bones}
    ride=bpy.data.actions.new('Ride');ride.use_fake_user=True;arm.animation_data.action=ride
    for b in arm.pose.bones:b.matrix_basis=base[b.name]
    bpy.context.view_layer.update()
    def point(name, child, target):
        bpy.context.view_layer.update();bone=arm.pose.bones[name];head=bone.head.copy()
        rotation=(arm.pose.bones[child].head-head).rotation_difference(Vector(target)-head)
        bone.matrix=Matrix.Translation(head)@rotation.to_matrix().to_4x4()@Matrix.Translation(-head)@bone.matrix
        bpy.context.view_layer.update()
    for side,sgn in [('Left',1),('Right',-1)]:
        point(side+'UpLeg',side+'Leg',(sgn*24,-12,40))
        point(side+'Leg',side+'Foot',(sgn*24,12,17))
        point(side+'Arm',side+'ForeArm',(sgn*30,-28,97))
        point(side+'ForeArm',side+'Hand',(sgn*34,-49,92.5))
    pose={b.name:(b.location.copy(),b.rotation_quaternion.copy()) for b in arm.pose.bones}
    for frame in [1,31,61]:
        for b in arm.pose.bones:
            b.location=pose[b.name][0];b.rotation_quaternion=pose[b.name][1]
            b.keyframe_insert('rotation_quaternion',frame=frame,group=b.name)
            b.keyframe_insert('location',frame=frame,group=b.name)
    arm.animation_data.action=bpy.data.actions.get('Idle');bpy.context.scene.frame_set(1)
export('characters/adrian_reference.glb',True)
(ROOT/'art/source/hero-reference.json').write_text(json.dumps({'reference':'User-provided Adrian_Reference.png inspected locally; image not redistributed','source':'Preserved adrian_signature.blend derivative','direction':'Exposed hairline, swept crown, half-tie and loose shoulder layers; conservative jaw/torso sculpt','ribbons':176,'limitations':'Existing coarse face/hands; conservative beard texture retained; cards and bounded springs, not strand groom or collision-complete hair. Leather outfit retained. Alternate tank-top not implemented.'},indent=2)+'\n')
print('REFERENCE_HERO_EXPORTED')
