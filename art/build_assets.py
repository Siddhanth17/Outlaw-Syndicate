"""Original modeled harbor kit and sedan; licensed human -> game-ready GLB.
Run with portable Blender: blender --background --python art/build_assets.py.
Blender coordinates: X right, -Y forward, Z up. glTF exporter converts to Y-up.
"""
import bpy, math, random
from pathlib import Path
from mathutils import Vector, Quaternion, Matrix
ROOT=Path(__file__).resolve().parents[1]
random.seed(42)

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def material(name,color,metal=0,rough=.5,texture=None,normal=None,emission=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    if emission:
        bs.inputs['Emission Color'].default_value=(*color,1);bs.inputs['Emission Strength'].default_value=emission
    if texture:
        n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(ROOT/'assets/textures'/texture))
        m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
    if normal:
        n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(ROOT/'assets/textures'/normal));n.image.colorspace_settings.name='Non-Color'
        b=m.node_tree.nodes.new('ShaderNodeNormalMap');b.inputs['Strength'].default_value=.5
        m.node_tree.links.new(n.outputs['Color'],b.inputs['Color']);m.node_tree.links.new(b.outputs['Normal'],bs.inputs['Normal'])
    return m

def finish(o,mat,bevel=0):
    if mat:o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('Manufactured edge radii','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def box(name,p,s,mat,bevel=.03):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,mat,bevel)

def cyl(name,p,r,depth,mat,rotation=(0,0,0),verts=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=p,rotation=rotation)
    o=bpy.context.object;o.name=name
    for f in o.data.polygons:f.use_smooth=True
    return finish(o,mat,.008)

def beam(name,a,b,r,mat):
    delta=Vector(b)-Vector(a);o=cyl(name,(Vector(a)+Vector(b))/2,r,delta.length,mat)
    o.rotation_euler=delta.to_track_quat('Z','Y').to_euler();return o

def mesh(name,verts,faces,mat):
    d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update()
    o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);finish(o,mat)
    return o

def text(name,body,p,size,mat,rot=(math.pi/2,0,0)):
    bpy.ops.object.text_add(location=p,rotation=rot);o=bpy.context.object;o.name=name;o.data.body=body;o.data.size=size;o.data.align_x='CENTER';o.data.extrude=.003;o.data.materials.append(mat)
    bpy.ops.object.convert(target='MESH');return o

def export(name,source=False):
    if not any(o.type=='ARMATURE' for o in bpy.context.scene.objects):
        # One draw surface per material instead of one draw call per modeled rib.
        groups={}
        for o in list(bpy.context.scene.objects):
            if o.type=='MESH':groups.setdefault(o.active_material.name if o.active_material else 'none',[]).append(o)
        for objects in groups.values():
            bpy.ops.object.select_all(action='DESELECT')
            for o in objects:o.select_set(True)
            bpy.context.view_layer.objects.active=objects[0]
            if len(objects)>1:bpy.ops.object.join()
    # UVs for real texture mapping; meshes retain authored bevel/topology detail.
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH' and not o.data.uv_layers:
            bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
            bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
    path=ROOT/'assets'/name;path.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_materials='EXPORT',export_cameras=False,export_lights=False)
    if source:
        bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/ (path.stem+'.blend')))
    print('EXPORTED',name)

def car():
    reset();paint=material('Oxide / automotive lacquer',(.32,.08,.035),.55,.26);trim=material('Black anodized trim',(.028,.033,.038),.65,.3);glass=material('Smoked blue automotive glazing',(.055,.12,.17),.5,.15);chrome=material('Machined aluminum',(.55,.6,.63),.85,.24);lamp=material('Headlight reflector',(.85,.88,.72),.5,.15,emission=1);red=material('Tail lenses',(.65,.015,.008),.3,.2,emission=1)
    glass.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.22
    glass.surface_render_method='DITHERED'
    paint.node_tree.nodes.get('Principled BSDF').inputs['Coat Weight'].default_value=.45
    paint.node_tree.nodes.get('Principled BSDF').inputs['Coat Roughness'].default_value=.18
    # Lofted closed hull: rounded shoulder line, belt line, hood and deck.
    sections=[(-2.15,.70,.38,.61),(-1.96,.91,.25,.76),(-1.35,.96,.22,.83),(-.72,.94,.22,.88),(.6,.94,.22,.86),(1.55,.92,.25,.78),(2.05,.77,.32,.67)]
    # Smooth longitudinal body profiles with a crowned hood/deck cross-section.
    controls=sections;sections=[]
    for i in range(len(controls)-1):
        p0=controls[max(0,i-1)];p1=controls[i];p2=controls[i+1];p3=controls[min(len(controls)-1,i+2)]
        for k in range(4):
            t=k/4
            values=[]
            for axis in range(4):
                values.append(.5*((2*p1[axis])+(-p0[axis]+p2[axis])*t+(2*p0[axis]-5*p1[axis]+4*p2[axis]-p3[axis])*t*t+(-p0[axis]+3*p1[axis]-3*p2[axis]+p3[axis])*t*t*t))
            sections.append(values)
    sections.append(controls[-1])
    verts=[];ring=12
    for y,w,low,high in sections:
        for x,z in [(-w*.82,low),(-w,low+.14),(-w,high-.13),(-w*.88,high),(-w*.45,high+.035),(0,high+.05),(w*.45,high+.035),(w*.88,high),(w,high-.13),(w,low+.14),(w*.82,low),(0,low-.015)]:verts.append((x,y,z))
    faces=[tuple(range(ring-1,-1,-1))]
    for i in range(len(sections)-1):
        for j in range(ring):faces.append((i*ring+j,i*ring+(j+1)%ring,(i+1)*ring+(j+1)%ring,(i+1)*ring+j))
    faces.append(tuple(range((len(sections)-1)*ring,len(sections)*ring)))
    hull=mesh('Sable GT / formed body shell',verts,faces,paint)
    # Cut actual wheel arches through the body with boolean cylinders.
    for y in [-1.32,1.30]:
        cutter=cyl('arch cutter',(0,y,.35),.46,3,None,(0,math.pi/2,0),32)
        bpy.context.view_layer.objects.active=hull;mod=hull.modifiers.new('Stamped wheel arch','BOOLEAN');mod.object=cutter;mod.operation='DIFFERENCE'
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
    cockpit=box('Cabin cavity tool',(0,.18,1.15),(1.50,1.80,1.80),None,0)
    bpy.context.view_layer.objects.active=hull
    cavity=hull.modifiers.new('Open passenger compartment','BOOLEAN');cavity.object=cockpit;cavity.operation='DIFFERENCE'
    bpy.ops.object.modifier_apply(modifier=cavity.name);bpy.data.objects.remove(cockpit,do_unlink=True)
    finish(hull,None,.045)
    for f in hull.data.polygons:f.use_smooth=True
    # Tapered greenhouse with separate glass panels and pillars.
    v=[(-.79,-.85,.82),(.79,-.85,.82),(-.66,-.35,1.45),(.66,-.35,1.45),(-.65,.69,1.43),(.65,.69,1.43),(-.8,1.18,.82),(.8,1.18,.82)]
    mesh('Windshield',v,[(0,1,3,2)],glass);mesh('Rear screen',v,[(4,5,7,6)],glass)
    mesh('Side glazing',v,[(0,2,4,6),(1,7,5,3)],glass)
    roof=mesh('Roof panel',v,[(2,3,5,4)],paint);sol=roof.modifiers.new('Roof thickness','SOLIDIFY');sol.thickness=.055;bpy.context.view_layer.objects.active=roof;bpy.ops.object.modifier_apply(modifier=sol.name)
    for a,b in [(0,2),(1,3),(4,6),(5,7),(2,4),(3,5),(0,6),(1,7)]:beam('Window surround',v[a],v[b],.025,trim)
    for side in [-1,1]:
        beam('B pillar',(side*.75,.23,.85),(side*.655,.23,1.44),.037,paint)
        for y in [-.3,.63]:box('Recessed door handle',(side*.95,y,.73),(.025,.16,.035),chrome,.01)
        box('Side mirror',(side*1.02,-.65,1.02),(.18,.25,.11),paint,.045)
        beam('Sill rail',(side*.92,-.82,.28),(side*.92,.79,.28),.045,trim)
        for y in [0,.85]:
            box('Seat',(side*.38,y,.66),(.53,.55,.12),trim,.08);box('Seat back',(side*.38,y+.18,.93),(.5,.13,.55),trim,.07)
    box('Front grille',(0,-2.12,.46),(1.25,.07,.2),trim,.025)
    for side in [-1,1]:
        for y in [-.8,.23,1.12]:beam('Door panel joint',(side*.943,y,.40),(side*.943,y,.80),.006,trim)
        beam('Hood panel joint',(side*.66,-1.85,.80),(side*.74,-.9,.89),.006,trim)
    for x in [-.62,.62]:
        box('Headlamp lens',(x,-2.04,.67),(.37,.08,.16),lamp,.04)
        box('Tail lamp',(x,2.02,.62),(.38,.08,.13),red,.03)
    for x in [-.5,-.25,0,.25,.5]:box('Grille fin',(x,-2.165,.46),(.025,.015,.13),chrome,.003)
    box('Rear bumper',(0,2.07,.36),(1.45,.08,.1),trim,.025)
    box('Dashboard',(0,-.64,.93),(1.4,.22,.18),trim,.04)
    box('Carpet floor',(0,.18,.27),(1.45,1.75,.03),trim,.015)

    text('Rear plate','VEYRA  08',(0,2.10,.52),.10,chrome,(-math.pi/2,0,math.pi))
    export('vehicles/sable_body.glb',True)
    reset();rubber=material('Treaded rubber',(.025,.028,.032),0,.88);alloy=material('Forged wheel',(.34,.39,.42),.85,.24);brake=material('Brake rotor',(.12,.14,.16),.8,.5)
    # Wheel axle local X, Godot wheel child follows steering and rotation.
    cyl('Tire',(0,0,0),.38,.23,rubber,(0,math.pi/2,0),40)
    for side in [-1,1]:
        bpy.ops.mesh.primitive_torus_add(major_radius=.255,minor_radius=.025,major_segments=32,minor_segments=8,location=(side*.125,0,0),rotation=(0,math.pi/2,0));finish(bpy.context.object,alloy)
        cyl('Brake disc',(side*.10,0,0),.19,.018,brake,(0,math.pi/2,0),32)
        cyl('Hub',(side*.145,0,0),.075,.04,brake,(0,math.pi/2,0),20)
        for j in range(10):
            a=j*math.tau/10;beam('Rim spoke',(side*.14,math.sin(a)*.09,math.cos(a)*.09),(side*.14,math.sin(a)*.26,math.cos(a)*.26),.018,alloy)
    for j in range(40):
        a=j*math.tau/40;o=box('Tread groove',(0,math.sin(a)*.378,math.cos(a)*.378),(.235,.017,.008),brake,.002);o.rotation_euler.x=-a
    export('vehicles/sable_wheel.glb')

def industrial():
    reset();concrete=material('Weathered concrete',(.4,.4,.38),rough=.9,texture='concrete_diff.jpg',normal='concrete_normal.jpg');steel=material('Galvanized rib steel',(.22,.28,.30),.65,.56);dark=material('Graphite steel',(.065,.08,.09),.75,.48);rust=material('Oxidized iron',(.3,.13,.055),.55,.75);window=material('Old wired glazing',(.12,.26,.32),.6,.26);warm=material('Warm practical lens',(1,.45,.12),emission=3)
    box('Concrete foundation',(0,0,.25),(24,16,.5),concrete,.08)
    # Gabled building volume with inset facade, corrugated cladding, roof seams.
    v=[(-12,-8,.5),(12,-8,.5),(12,8,.5),(-12,8,.5),(-12,-8,6),(12,-8,6),(12,8,6),(-12,8,6),(0,-8,8),(0,8,8)]
    mesh('Gabled warehouse shell',v,[(0,1,5,8,4),(3,7,9,6,2),(0,4,7,3),(1,2,6,5),(4,8,9,7),(8,5,6,9)],steel)
    for x in range(-12,13,3):
        beam('Structural portal',(x,-8.08,.5),(x,-8.08,6),.08,dark)
        for z in [2,5.5]:beam('Facade horizontal',(x,-8.1,z),(min(x+3,12),-8.1,z),.035,dark)
    for x in [i*.25-12 for i in range(97)]:
        box('Corrugated facade rib',(x,-8.035,3.3),(.045,.05,5.3),steel,.008)
    for x in [-7,0,7]:
        box('Loading bay surround',(x,-8.16,2),(5.5,.18,3.6),dark,.025)
        box('Roller shutter',(x,-8.28,2.05),(4.9,.08,3.1),steel,.015)
        for z in [i*.16+.6 for i in range(19)]:box('Shutter slat',(x,-8.34,z),(4.85,.025,.025),dark,.004)
        box('Dock bumper',(x,-8.7,.38),(5.6,.75,.4),concrete,.045)
        for side in [-1,1]:cyl('Dock bollard',(x+side*2.8,-8.9,.65),.11,1.3,rust)
        box('Bay luminaire',(x,-8.45,4.45),(1.2,.3,.15),dark)
        box('Bay light diffuser',(x,-8.48,4.36),(.95,.18,.03),warm,.005)
    for x in [-9,-6,-3,0,3,6,9]:
        box('Clerestory frame',(x,-8.12,5.2),(2.4,.15,.8),dark,.01)
        box('Clerestory glass',(x,-8.22,5.2),(2.2,.03,.6),window,.005)
        beam('Glass mullion',(x,-8.25,4.85),(x,-8.25,5.55),.023,dark)
    for side in [-1,1]:
        beam('Roof gutter',(side*12,-8.3,6),(side*12,8.3,6),.09,dark)
        beam('Drainpipe',(side*11.7,-8.3,.5),(side*11.7,-8.3,6),.065,rust)
    for y in range(-8,9):
        beam('Standing seam',(-12,y,6.03),(0,y,8.03),.025,dark);beam('Standing seam',(0,y,8.03),(12,y,6.03),.025,dark)
    for x in [-5,4]:
        cyl('Roof vent',(x,3,7.5),.38,1.5,dark);cyl('Rain cap',(x,3,8.3),.55,.12,steel)
    export('environment/warehouse.glb',True)
    reset();paint=material('Marine enamel',(.13,.28,.31),.55,.65);iron=material('Container hardware',(.18,.2,.20),.8,.5);white=material('Stencil paint',(.66,.65,.55),rough=.8)
    box('Container envelope',(0,0,1.3),(2.42,6.04,2.6),paint,.055)
    for side in [-1,1]:
        for i in range(30):box('Pressed corrugation',(side*1.22,-2.9+i*.20,1.3),(.07,.09,2.35),paint,.022)
        for z in [.08,2.53]:box('Frame rail',(side*1.22,0,z),(.12,6.1,.14),iron,.018)
        for y in [-3,3]:box('Corner casting',(side*1.20,y,1.3),(.15,.16,2.6),iron,.02)
    for x in [-.59,.59]:
        box('Cargo door',(x,-3.055,1.3),(1.12,.08,2.4),paint,.025)
        for dx in [-.38,.38]:
            cyl('Door locking rod',(x+dx,-3.14,1.3),.024,2.15,iron)
            beam('Locking lever',(x+dx,-3.19,1.1),(x+dx+.22,-3.19,1.1),.025,iron)
    text('Container ID','VYR  0826\nMAX GROSS  30 480 KG',(0,-3.15,1.85),.13,white)
    export('environment/container.glb',True)
    reset();metal=material('Lamp galvanized steel',(.14,.18,.20),.8,.45);light=material('Sodium bulb',(1,.52,.18),emission=4)
    cyl('Flanged foot',(0,0,.08),.25,.16,metal);cyl('Tapered mast',(0,0,3.5),.08,7,metal)
    beam('Outreach',(0,0,6.95),(0,-1.5,7.2),.065,metal)
    box('Luminaire housing',(0,-1.55,7.2),(.45,.9,.18),metal,.08);box('Lens',(0,-1.55,7.10),(.35,.7,.03),light,.03)
    export('environment/streetlamp.glb')
    reset();metal=material('Fence steel',(.22,.25,.24),.8,.65)
    for x in [-2,2]:cyl('Fence post',(x,0,1.3),.06,2.6,metal)
    for z in [.15,2.35]:beam('Rail',(-2,0,z),(2,0,z),.035,metal)
    for i in range(27):
        x=-2+i*.15
        beam('Wire',(x,0,.2),(min(2,x+1.0),0,2.3),.008,metal)
        beam('Wire',(x,0,2.3),(min(2,x+1.0),0,.2),.008,metal)
    export('environment/fence.glb')
    reset();wood=material('Pallet worn timber',(.25,.17,.09),rough=.9);steel=material('Drum painted steel',(.15,.25,.24),.65,.55);yellow=material('Safety paint',(.7,.39,.07),.3,.65)
    for z in [.06,.23]:
        for x in [-.5,-.25,0,.25,.5]:box('Pallet board',(x,0,z),(.20,1,.07),wood,.01)
    for x in [-.45,0,.45]:box('Pallet stringer',(x,0,.14),(.1,.9,.15),wood,.01)
    for x in [-.32,.32]:
        cyl('Oil drum',(x,0,.79),.24,.95,steel,verts=24)
        for z in [.38,.65,1.04,1.24]:cyl('Drum rolled seam',(x,0,z),.25,.035,yellow,verts=24)
    export('environment/cargo.glb')
    reset();orange=material('Port crane enamel',(.48,.25,.075),.55,.65);steel=material('Crane structure',(.10,.14,.16),.8,.55)
    for x in [-6,6]:
        for y in [-4,4]:
            beam('A-frame leg',(x,y,0),(x*.6,y*.7,19),.28,orange)
            cyl('Rail bogie',(x,y,.5),.7,.5,steel,(math.pi/2,0,0))
    for z in [9,15,19]:
        for y in [-2.8,2.8]:beam('Transverse beam',(-4,y,z),(4,y,z),.2,orange)
    for x in [-3.6,3.6]:
        beam('Boom lower',(x,-15,20),(x,10,20),.2,orange);beam('Boom upper',(x,-15,23),(x,10,23),.18,orange)
        for y in range(-15,10,3):
            beam('Lattice diagonal',(x,y,20),(x,y+3,23),.10,steel)
            beam('Lattice diagonal',(x,y,23),(x,y+3,20),.10,steel)
        beam('Lift cable',(x,-9,20),(x,-9,5),.035,steel)
    beam('Spreader',(-4,-9,5),(4,-9,5),.24,orange)
    export('environment/crane.glb',True)
    reset();dark=material('Pistol finish',(.035,.045,.052),.8,.33);grip=material('Polymer grip',(.045,.05,.05),rough=.9)
    box('Slide',(0,-.08,0),(.04,.22,.045),dark,.008);o=box('Grip',(0,.005,-.065),(.035,.07,.10),grip,.009);o.rotation_euler.x=-.2
    cyl('Barrel',(0,-.20,0),.012,.04,dark,(math.pi/2,0,0));export('vehicles/sidearm.glb')

def human():
    reset();bpy.ops.import_scene.gltf(filepath=str(ROOT/'art/source/camper-cc0.glb'))
    for o in list(bpy.context.scene.objects):
        if o.name=='Icosphere':bpy.data.objects.remove(o,do_unlink=True)
    arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    arm.animation_data_create();walk=bpy.data.actions.get('Walk');run=bpy.data.actions.get('Run')
    # Source clips use centimeters in skeleton with 0.01 armature scale.
    arm.animation_data.action=walk;bpy.context.scene.frame_set(1)
    bpy.context.scene.render.fps=30
    # Keep imported timing at 24 fps by rescaling original keys for 30 fps export.
    for action in [walk,run]:
        for curve in action.fcurves:
            for key in curve.keyframe_points:
                key.co.x*=1.25;key.handle_left.x*=1.25;key.handle_right.x*=1.25
    sprint=run.copy();sprint.name='Sprint';sprint.use_fake_user=True
    for curve in sprint.fcurves:
        for key in curve.keyframe_points:
            key.co.x*=.78;key.handle_left.x*=.78;key.handle_right.x*=.78
    # Neutral pose is averaged across a full gait, avoiding a frozen crossed-leg step.
    samples={b.name:[] for b in arm.pose.bones}
    arm.animation_data.action=walk
    for frame in range(1,33):
        bpy.context.scene.frame_set(frame)
        for b in arm.pose.bones:samples[b.name].append(b.matrix_basis.copy())
    base={}
    for name,matrices in samples.items():
        locations=[m.to_translation() for m in matrices];quats=[m.to_quaternion() for m in matrices]
        ref=quats[0]
        for q in quats:
            if q.dot(ref)<0:q.negate()
        q=Quaternion(tuple(sum(q[i] for q in quats)/len(quats) for i in range(4)));q.normalize()
        base[name]=Matrix.LocRotScale(sum(locations,Vector())/len(locations),q,Vector((1,1,1)))
    def action(name,length,kind):
        a=bpy.data.actions.new(name);a.use_fake_user=True;arm.animation_data.action=a
        for frame in range(1,length+1,3):
            t=(frame-1)/(length-1);wave=math.sin(t*math.tau)
            for b in arm.pose.bones:b.matrix_basis=base[b.name]
            # Small authored poses layered over the source human skeleton.
            def rotate(bone,axis,angle):
                b=arm.pose.bones.get(bone)
                if b:b.rotation_mode='QUATERNION';b.rotation_quaternion=b.rotation_quaternion @ Quaternion(axis,angle)
            rotate('Spine',(1,0,0),.015*wave)
            if kind in ['interact','reload','aim','shoot','enter','exit']:
                def point(bone,child,target):
                    bpy.context.view_layer.update()
                    b=arm.pose.bones[bone];c=arm.pose.bones[child]
                    head=b.head.copy();current=c.head-head;desired=Vector(target)-head
                    q=current.rotation_difference(desired)
                    b.matrix=Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ b.matrix
                    bpy.context.view_layer.update()
                if kind in ['aim','shoot']:
                    recoil=4*math.sin(t*math.pi) if kind=='shoot' else 0
                    point('RightArm','RightForeArm',(-23,-23,137))
                    point('RightForeArm','RightHand',(-10,-55+recoil,141))
                    point('LeftArm','LeftForeArm',(20,-20,132))
                    point('LeftForeArm','LeftHand',(-3,-49,137))
                elif kind=='reload':
                    point('RightArm','RightForeArm',(-22,-17,128))
                    point('RightForeArm','RightHand',(-6,-30,135))
                    point('LeftArm','LeftForeArm',(20,-17,127))
                    point('LeftForeArm','LeftHand',(-2,-29,127+6*math.sin(t*math.pi)))
                else:
                    point('RightArm','RightForeArm',(-22,-15,125))
                    point('RightForeArm','RightHand',(-15,-35,123+5*math.sin(t*math.pi)))
            if kind=='shoot':rotate('Spine',(1,0,0),-.05*math.sin(t*math.pi))
            if kind in ['jump','land']:
                rotate('LeftUpLeg',(1,0,0),-.3*math.sin(t*math.pi));rotate('RightUpLeg',(1,0,0),-.3*math.sin(t*math.pi))
                rotate('LeftLeg',(1,0,0),.5*math.sin(t*math.pi));rotate('RightLeg',(1,0,0),.5*math.sin(t*math.pi))
            if kind=='turn':rotate('Spine',(0,1,0),.10*wave)
            for b in arm.pose.bones:
                b.keyframe_insert('rotation_quaternion',frame=frame,group=b.name)
                b.keyframe_insert('location',frame=frame,group=b.name)
        return a
    for name,length in [('Idle',61),('Interact',31),('Aim',31),('Shoot',10),('Reload',46),('Jump',22),('Land',13),('Turn',31),('Enter',31),('Exit',31)]:action(name,length,name.lower())
    # Original art direction: subdued oxblood overshirt; no logos added.
    for m in bpy.data.materials:
        if m.use_nodes:
            bs=m.node_tree.nodes.get('Principled BSDF')
            if bs:bs.inputs['Roughness'].default_value=.8
    arm.animation_data.action=walk
    export('characters/adrian.glb',True)

if __name__ == '__main__':
    car();industrial();human()
