"""Original reference-directed additions. User reference images are never imported.
Run after build_assets.py; uses its reusable modeling helpers and existing sources.
"""
import sys, math, json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
import numpy as np

def refine_human():
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/adrian.blend'))
    arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    arm.animation_data.action=None
    for b in arm.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.object.mode_set(mode='EDIT')
    chains=[('HairCrown','Head',(0,2,171),(0,6,175),(0,10,173)),('HairFringe','Head',(0,-3,172),(0,-7,174),(0,-10,171)),('HemLeft','Hips',(13,9,109),(13,11,98),(13,13,88)),('HemRight','Hips',(-13,9,109),(-13,11,98),(-13,13,88))]
    for name,parent,a,b,c in chains:
        root=arm.data.edit_bones.new(name);root.head=a;root.tail=b;root.parent=arm.data.edit_bones[parent]
        tip=arm.data.edit_bones.new(name+'Tip');tip.head=b;tip.tail=c;tip.parent=root;tip.use_connect=True
    bpy.ops.object.mode_set(mode='OBJECT')
    body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    for name,_,_,_,_ in chains:
        body.vertex_groups.new(name=name);body.vertex_groups.new(name=name+'Tip')
    image=next(n.image for m in body.data.materials for n in m.node_tree.nodes if n.type=='TEX_IMAGE')
    pixels=np.array(image.pixels[:],dtype=np.float32).reshape(image.size[1],image.size[0],4)
    colors={}
    for loop in body.data.loops:
        uv=body.data.uv_layers.active.data[loop.index].uv
        colors[loop.vertex_index]=pixels[int(uv.y*(image.size[1]-1)),int(uv.x*(image.size[0]-1)),:3]
    count={'hair':0,'hem':0}
    def weight(v,name,amount):
        for g in list(v.groups):body.vertex_groups[g.group].add([v.index],g.weight*(1-amount),'REPLACE')
        body.vertex_groups[name].add([v.index],amount,'REPLACE')
    for v in body.data.vertices:
        x,y,z=body.matrix_world @ v.co
        rgb=colors.get(v.index,np.ones(3))
        if z>1.62 and max(rgb)<.38 and (y>-.025 or z>1.70):
            name='HairFringe' if y<-.015 else 'HairCrown'
            amount=min(.85,max(0,(z-1.62)/.13))
            weight(v,name+('Tip' if z>1.74 else ''),amount);count['hair']+=1
        elif .91<z<1.07 and y>.035 and abs(x)<.30:
            name='HemLeft' if x>0 else 'HemRight'
            weight(v,name+('Tip' if z<.97 else ''),min(.65,(1.07-z)*4));count['hem']+=1
    assert count['hair']>30 and count['hem']>30,count
    for v in body.data.vertices:
        influences=sorted([(g.group,g.weight) for g in v.groups if g.weight>0.0001],key=lambda x:x[1],reverse=True)
        if len(influences)>4:
            for group,amount in influences[4:]:body.vertex_groups[group].remove([v.index])
            total=sum(amount for group,amount in influences[:4])
            for group,amount in influences[:4]:body.vertex_groups[group].add([v.index],amount/total,'REPLACE')
    print('DEFORMING VERTICES',count)
    # Original seated pose; preserve the source rig and all existing clips.
    idle=bpy.data.actions['Idle'];arm.animation_data.action=idle;bpy.context.scene.frame_set(1)
    base={b.name:b.matrix_basis.copy() for b in arm.pose.bones}
    drive=bpy.data.actions.new('Drive');drive.use_fake_user=True;arm.animation_data.action=drive
    def point(name,child,target):
        bpy.context.view_layer.update();b=arm.pose.bones[name];head=b.head.copy()
        q=(arm.pose.bones[child].head-head).rotation_difference(Vector(target)-head)
        b.matrix=Matrix.Translation(head)@q.to_matrix().to_4x4()@Matrix.Translation(-head)@b.matrix
        bpy.context.view_layer.update()
    for b in arm.pose.bones:b.matrix_basis=base[b.name]
    bpy.context.view_layer.update()
    hip=arm.pose.bones['Hips'];m=hip.matrix.copy();m.translation.z=65.5;hip.matrix=m
    bpy.context.view_layer.update()
    for side,sgn in [('Left',1),('Right',-1)]:
        point(side+'UpLeg',side+'Leg',(sgn*13,-30,48))
        point(side+'Leg',side+'Foot',(sgn*13,-49,25))
        point(side+'Arm',side+'ForeArm',(sgn*23,-23,108))
        point(side+'ForeArm',side+'Hand',(sgn*14,-47,106))
    pose={b.name:(b.location.copy(),b.rotation_quaternion.copy()) for b in arm.pose.bones}
    for frame in [1,31,61]:
        for b in arm.pose.bones:
            b.location=pose[b.name][0];b.rotation_quaternion=pose[b.name][1]
            b.keyframe_insert('rotation_quaternion',frame=frame,group=b.name)
            b.keyframe_insert('location',frame=frame,group=b.name)
    arm.animation_data.action=idle
    # Smooth shaded surface and separate skin/hair roughness from woven clothing.
    skin=body.data.materials[0].copy();skin.name='Adrian skin / textured'
    skin.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.54
    hair=body.data.materials[0].copy();hair.name='Adrian hair / textured'
    hair.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.68
    body.data.materials.append(skin);body.data.materials.append(hair)
    for poly in body.data.polygons:
        poly.use_smooth=True
        center=sum((body.matrix_world @ body.data.vertices[i].co for i in poly.vertices),Vector())/len(poly.vertices)
        if center.z>1.47 or (abs(center.x)>.42 and 1.0<center.z<1.25):
            poly.material_index=2 if center.z>1.64 and max(colors.get(poly.vertices[0],np.ones(3)))<.38 else 1
    export('characters/adrian.glb',True)
    (ROOT/'art/source/secondary-weights.json').write_text(json.dumps(count,indent=2))

def warehouse_variants():
    for variant in range(3):
        bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/warehouse.blend'))
        steel=material('Weathered service steel',(.17,.21,.22),.5,.65)
        rubber=material('Cable insulation',(.025,.03,.025),rough=.9)
        sign=material('Safety enamel',(.65,.45,.15),rough=.65)
        for x in [8.5,10.3]:
            box('Service electrical cabinet',(x,-8.25,1.6),(.8,.3,1.1),steel,.04)
            box('Cabinet seam',(x,-8.42,1.6),(.72,.012,1.02),rubber,.01)
            beam('Electrical conduit',(x,-8.4,.5),(x,-8.4,4.3),.025,steel)
        for z in [1,3.8]:beam('Horizontal conduit',(8.5,-8.4,z),(11,-8.4,z),.025,steel)
        beam('CCTV mount',(10,-8.4,5.7),(10,-9,5.7),.04,steel)
        cam=box('CCTV camera',(10,-9,5.6),(.22,.38,.16),steel,.04);cam.rotation_euler.x=.3
        box('Safety notice panel',(-10,-8.20,2),(.95,.08,.8),sign,.02)
        text('Notice','RESTRICTED\nCCTV IN USE',(-10,-8.26,2.1),.13,rubber)
        if variant==1:
            for x in [-6,6]:
                box('Rooftop HVAC',(x,1,8),(2.5,2,1.3),steel,.08)
                for j in range(9):box('Vent grille',(x-1+j*.25,-.03,8),(.05,.03,.8),rubber,.005)
        elif variant==2:
            for y in [-2,0,2]:beam('Service pipe rack',(-10,y,7),(-2,y,8.3),.12,steel)
        names=['VEYRA FREIGHT / 24H','CROSS ENGINEERING','NORTH QUAY / COLD STORAGE']
        text('Company fascia',names[variant],(0,-8.25,6.3),.38,sign)
        export('environment/warehouse_realism_%d.glb'%variant,True)

def props():
    reset();metal=material('Cast iron',(.07,.08,.08),.65,.85)
    cyl('Manhole recessed plate',(0,0,.015),.48,.03,metal,verts=48)
    for r in [.15,.3,.45]:
        bpy.ops.mesh.primitive_torus_add(major_radius=r,minor_radius=.008,major_segments=40,minor_segments=6,location=(0,0,.035));finish(bpy.context.object,metal)
    for i in range(-5,6):box('Traction grid',(i*.07,0,.035),(.012,.6,.008),metal,.002)
    export('environment/manhole.glb')
    reset();steel=material('Drain cast steel',(.08,.1,.11),.65,.8)
    for x in [-.17,.17]:box('Drain frame',(x,0,.015),(.035,1.2,.03),steel,.005)
    for i in range(18):box('Drain grate',(0,-.57+i*.067,.017),(.32,.026,.035),steel,.004)
    export('environment/drain.glb')
    reset();paint=material('Forklift safety enamel',(.62,.32,.04),.3,.5);dark=material('Hydraulic steel',(.07,.09,.10),.7,.45);rubber=material('Solid tires',(.025,.027,.03),rough=.9)
    box('Counterweight',(0,.75,.65),(1.2,.7,.9),paint,.18);box('Chassis',(0,0,.38),(1.25,2.1,.32),paint,.08)
    for x in [-.6,.6]:
        for y in [-.65,.65]:cyl('Forklift wheel',(x,y,.3),.3,.22,rubber,(0,math.pi/2,0),24)
        beam('Mast rail',(x,-1.1,.4),(x,-1.1,2.7),.065,dark)
        beam('Overhead cage',(x,.65,2),(x,-.65,2),.04,dark)
        for y in [-.65,.65]:beam('Cage post',(x,y,.5),(x,y,2),.04,dark)
    for x in [-.35,.35]:
        box('Fork blade',(x,-1.7,.15),(.12,1.4,.06),dark,.015)
        beam('Fork back',(x,-1.05,.15),(x,-1.05,1.1),.05,dark)
    box('Operator seat',(0,.3,.85),(.6,.6,.15),dark,.06)
    box('Seat back',(0,.55,1.15),(.6,.12,.6),dark,.06)
    export('environment/forklift.glb',True)
    reset();rubber=material('Wheel grip',(.035,.04,.045),rough=.7);alloy=material('Wheel spokes',(.18,.2,.22),.6,.4)
    bpy.ops.mesh.primitive_torus_add(major_radius=.16,minor_radius=.018,major_segments=32,minor_segments=8,rotation=(math.pi/2,0,0));finish(bpy.context.object,rubber)
    for a in [0,2.1,4.2]:beam('Steering spoke',(0,0,0),(math.sin(a)*.14,0,math.cos(a)*.14),.012,alloy)
    export('vehicles/steering.glb')

car();human();warehouse_variants();props();refine_human()
