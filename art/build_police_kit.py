"""Original Veyra handset and furnished neighborhood police-office kit, meters.
Project geometry only; existing credited Poly Haven plaster maps are reused.
This is prototype game art, not final station visual acceptance.
"""
import sys, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *

def b(name,p,size,mat,bevel=.02):
    return box(name,(p[0],-p[2],p[1]),(size[0],size[2],size[1]),mat,bevel)

def tube(name,a,c,r,mat):
    start=Vector((a[0],-a[2],a[1]));end=Vector((c[0],-c[2],c[1]))
    obj=cyl(name,(start+end)*.5,r,(end-start).length,mat)
    obj.rotation_mode='QUATERNION';obj.rotation_quaternion=(end-start).to_track_quat('Z','Y')
    return obj

reset()
case=material('Original handset graphite alloy',(.025,.03,.035),.65,.26)
glass=material('Original handset dark display',(.015,.035,.042),.2,.15)
silver=material('Handset machined trim',(.24,.28,.3),.8,.24)
b('Rounded handset body',(0,0,0),(.071,.145,.009),case,.006)
b('Inset display glass',(0,0,-.005),(.063,.131,.002),glass,.004)
b('Earpiece slot',(0,.058,-.0065),(.018,.002,.001),case,.0008)
for side in [-1,1]:b('Physical side key',(side*.0357,.022,.001),(.0018,.014,.003),silver,.0007)
tube('Camera lens bezel',(.022,.055,.005),(.022,.055,.007),.004,silver)
export('props/veyra_handset.glb',source=True)

reset()
wall=material('Police office plaster',(.48,.52,.5),rough=.92,texture='concrete_diff.jpg',normal='concrete_normal.jpg')
floor=material('Office terrazzo',(.22,.25,.25),rough=.62)
metal=material('Powder coated office steel',(.055,.075,.085),.65,.38)
blue=material('Veyra blue enamel',(.035,.12,.19),.2,.4)
glazing=material('Office glazing',(.09,.17,.18),.45,.19)
b('Station floor slab',(0,-.08,0),(12,.16,10),floor)
b('Weatherproof roof',(0,3.3,0),(12.4,.22,10.4),metal)
for x in [-6,6]:b('Station side wall',(x,1.6,0),(.22,3.2,10),wall)
b('Rear exterior wall',(0,1.6,-5),(12,3.2,.22),wall)
for x in [-3.55,3.55]:
    b('Front masonry below glazing',(x,.5,5),(4.9,1,.22),wall)
    b('Front glazing',(x,1.85,5),(4.85,1.65,.045),glazing,.006)
    for dx in [-2.45,0,2.45]:b('Glazing mullion',(x+dx,1.9,5.03),(.065,1.8,.08),metal,.006)
b('Door head',(0,2.95,5),(2.1,.5,.22),wall)
for x in [-1.05,1.05]:b('Door jamb',(x,1.3,5.02),(.12,2.6,.18),metal,.008)
b('Civic blue sign',(0,2.96,5.18),(4.8,.38,.08),blue)
text('Original station lettering','VEYRA / NEIGHBORHOOD POLICE',(0,-5.23,2.86),.16,material('Station lettering',(.83,.88,.84),rough=.7))
export('environment/veyra_station_shell.glb',source=True)

reset()
oak=material('Station reception walnut',(.13,.075,.035),rough=.58)
steel=material('Station furniture steel',(.055,.075,.085),.6,.38)
plastic=material('Station chair upholstery',(.04,.065,.075),rough=.7)
paper=material('Original case paperwork',(.72,.72,.64),rough=.95)
screen=material('Original terminal screen',(.045,.15,.17),.2,.38,emission=.2)
stone=material('Reception countertop',(.18,.22,.23),rough=.42)
# Curved reception, extruded as a continuous annular surface rather than stacked blocks.
vertices=[];faces=[]
for i in range(33):
    angle=math.radians(25+130*i/32)
    for radius,y in [(1.35,0),(2.05,0),(1.35,1),(2.05,1)]:
        vertices.append((radius*math.cos(angle),-(radius*math.sin(angle)+.2),y))
for i in range(32):
    a=i*4;c=(i+1)*4
    faces.extend([(a,a+1,c+1,c),(a+2,c+2,c+3,a+3),(a,c,c+2,a+2),(a+1,a+3,c+3,c+1)])
faces.extend([(0,2,3,1),(128,129,131,130)])
mesh=bpy.data.meshes.new('Curved reception joinery');mesh.from_pydata(vertices,[],faces);mesh.update()
obj=bpy.data.objects.new('Continuous curved reception desk',mesh);bpy.context.collection.objects.link(obj);finish(obj,oak,.025)
for x,z in [(-3,-2),(-3,1),(1.5,-3.5)]:
    b('Officer desk top',(x,.77,z),(1.7,.07,.8),oak)
    for dx in [-.7,.7]:
        for dz in [-.29,.29]:tube('Desk steel leg',(x+dx,.04,z+dz),(x+dx,.73,z+dz),.025,steel)
    b('Terminal screen',(x,.99,z-.16),(.55,.33,.045),steel,.018)
    b('Screen display',(x,.99,z-.13),(.49,.27,.01),screen,.008)
    b('Terminal stand',(x,.84,z-.16),(.045,.15,.045),steel,.006)
    b('Keyboard',(x,.823,z+.15),(.36,.025,.13),steel,.009)
    b('Case folder',(x+.52,.821,z+.04),(.23,.012,.3),paper,.004)
    b('Chair padded seat',(x,.44,z+.9),(.48,.1,.48),plastic,.07)
    b('Chair curved back',(x,.73,z+1.1),(.48,.48,.075),plastic,.05)
    for dx in [-.18,.18]:
        for dz in [-.18,.18]:tube('Chair leg',(x+dx,.03,z+.9+dz),(x+dx,.4,z+.9+dz),.018,steel)
for x in [-5.35,-4.5]:
    b('Filing cabinet',(x,.65,-4.3),(.7,1.3,.5),steel)
    for y in [.25,.65,1.05]:
        b('Individual file drawer',(x,y,-4.035),(.63,.32,.025),oak,.008)
        tube('Drawer pull',(x-.09,y,-4.0),(x+.09,y,-4.0),.012,steel)
# Secure holding area: visible bars, door and a proper bench, collision added in scene.
for z in [-4.7,-1.4]:
    for x in [2.2+i*.22 for i in range(16)]:tube('Holding room steel bar',(x,.04,z),(x,2.6,z),.018,steel)
    for y in [.08,1.25,2.55]:tube('Holding horizontal rail',(2.2,y,z),(5.5,y,z),.025,steel)
for z in [-4.7+i*.22 for i in range(16)]:tube('Holding side bars',(2.2,.04,z),(2.2,2.6,z),.018,steel)
b('Holding bench',(4,.45,-4.25),(2.4,.1,.48),oak)
for x in [3,5]:b('Bench pedestal',(x,.22,-4.25),(.12,.44,.42),steel)
for x in [-5.5,5.5]:
    b('Wall CCTV enclosure',(x,2.8,3.8),(.16,.12,.3),steel,.025)
    tube('CCTV lens',(x,2.8,3.96),(x,2.8,3.98),.04,screen)
export('environment/veyra_station_equipment.glb',source=True)
