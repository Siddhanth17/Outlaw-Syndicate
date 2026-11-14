"""Original unbranded commuter motorcycle prototype; editable modeled parts."""
import sys, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
reset()
black=material('Motorcycle charcoal powdercoat',(.025,.03,.033),.55,.38)
silver=material('Motorcycle brushed metal',(.27,.30,.32),.8,.3)
rubber=material('Motorcycle rubber',(.018,.019,.02),rough=.88)
paint=material('Motorcycle midnight blue tank',(.025,.08,.10),.65,.3)
seat=material('Motorcycle stitched saddle',(.027,.024,.023),rough=.82)
for x in [-.13,.13]:
    for a,b in [((x,-.5,.62),(x,.53,.40)),((x,.53,.4),(x,.08,.86)),((x,.08,.86),(x,-.5,.62)),((x,.05,.42),(x,-.55,.92))]:beam('Triangulated tubular frame',a,b,.025,black)
    beam('Rear spring damper',(x,.53,.38),(x,.25,.83),.035,silver)
    beam('Fork tube',(x,-.72,.33),(x,-.48,1.05),.025,silver)
    beam('Swing arm',(x,.70,.32),(x,.12,.48),.025,black)
    beam('Footrest',(x,.15,.42),(x*2,.15,.42),.018,silver)
    for i in range(7):box('Engine cooling fin',(0,-.05,.53+i*.023),(.32,.31,.012),silver,.004)
    cyl('Engine case',(x,-.04,.52),.13,.10,black,(0,math.pi/2,0),24)
    beam('Exhaust header',(x,-.18,.48),(x,.22,.30),.027,silver)
    cyl('Exhaust silencer',(x*1.7,.46,.34),.055,.48,black,(math.pi/2,0,0),24)
bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=(0,-.21,.83));tank=bpy.context.object;tank.name='Sculpted fuel tank';tank.scale=(.22,.34,.17);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(tank,paint)
for f in tank.data.polygons:f.use_smooth=True
box('Rider saddle',(0,.25,.87),(.36,.54,.095),seat,.045)
beam('Handlebar riser',(0,-.49,1.05),(0,-.29,1.17),.025,silver)
beam('Handlebar',(-.35,-.29,1.17),(.35,-.29,1.17),.018,silver)
for x in [-.32,.32]:
    beam('Grip',(x,-.29,1.17),(x*1.16,-.29,1.17),.023,rubber)
    beam('Mirror stem',(x,-.29,1.17),(x,-.24,1.36),.009,silver)
    box('Mirror',(x,-.24,1.36),(.13,.055,.075),black,.025)
glass=material('Motorcycle headlight',(.7,.76,.67),.4,.18,emission=1)
cyl('Headlight bucket',(0,-.57,.97),.09,.10,black,(math.pi/2,0,0),32)
cyl('Headlight lens',(0,-.63,.97),.078,.015,glass,(math.pi/2,0,0),32)
red=material('Motorcycle rear lamp',(.5,.015,.01),rough=.25,emission=.5)
box('Rear lamp',(0,.60,.87),(.16,.04,.045),red,.012)
export('vehicles/harrier_bike.glb',True)
reset();rubber=material('Motorcycle tread rubber',(.018,.019,.02),rough=.88);metal=material('Motorcycle wheel alloy',(.20,.23,.25),.85,.29)
bpy.ops.mesh.primitive_torus_add(major_radius=.245,minor_radius=.075,major_segments=64,minor_segments=16,rotation=(0,math.pi/2,0));finish(bpy.context.object,rubber)
for face in bpy.context.object.data.polygons: face.use_smooth=True
bpy.ops.mesh.primitive_torus_add(major_radius=.188,minor_radius=.017,major_segments=48,minor_segments=8,rotation=(0,math.pi/2,0));finish(bpy.context.object,metal)
for face in bpy.context.object.data.polygons: face.use_smooth=True
cyl('Axle hub',(0,0,0),.045,.12,metal,(0,math.pi/2,0),24)
cyl('Brake rotor',(.045,0,0),.095,.008,metal,(0,math.pi/2,0),32)
for j in range(12):
    a=j*math.tau/12;beam('Wheel spoke',(0,0,0),(0,math.sin(a)*.22,math.cos(a)*.22),.008,metal)
export('vehicles/harrier_wheel.glb',True)
print('ORIGINAL_BIKE_EXPORTED')
