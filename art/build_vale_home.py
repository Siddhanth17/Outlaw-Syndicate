"""Original furnished Vale residence. Blender meters, authored soft surfaces and joinery.
Uses only project geometry and existing credited Poly Haven concrete maps.
"""
import sys,math,random
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
random.seed(41)
reset()
plaster=material('Lime plaster',(.54,.51,.43),rough=.95,texture='concrete_diff.jpg',normal='concrete_normal.jpg')
oak=material('Smoked oak',(.15,.075,.035),rough=.62,texture='vale-oak.png',normal='vale-oak-normal.png')
walnut=material('Walnut end grain',(.065,.028,.014),rough=.57)
metal=material('Dark powder coated iron',(.025,.031,.032),.65,.36)
linen=material('Warm woven linen',(.39,.36,.27),rough=.94,texture='vale-linen.png',normal='vale-linen-normal.png')
leather=material('Weathered tobacco leather',(.16,.07,.028),rough=.64,texture='vale-leather.png',normal='vale-leather-normal.png')
cream=material('Ceramic enamel',(.74,.73,.64),rough=.28)
glass=material('Cool residential glazing',(.11,.21,.24),.45,.19)
paper=material('Paper and book edges',(.68,.61,.46),rough=.92)
brass=material('Aged brass',(.42,.25,.065),.75,.31)
green=material('Houseplant leaves',(.045,.12,.052),rough=.8)
lamp=material('Warm lamp shade',(.8,.5,.21),rough=.8,emission=.6)
ink=material('Dark printed ink',(.016,.022,.024),rough=.95)
cloth=material('Slate blue quilt',(.075,.13,.16),rough=.97,texture='vale-quilt.png',normal='vale-quilt-normal.png')
def b(name,p,s,mat,bevel=.025):return box(name,(p[0],-p[2],p[1]),(s[0],s[2],s[1]),mat,bevel)
def tube(name,a,bb,r,mat):return beam(name,(a[0],-a[2],a[1]),(bb[0],-bb[2],bb[1]),r,mat)
def soft(name,p,s,mat):
    o=b(name,p,s,mat,min(s)*.35)
    mod=o.modifiers.new('Soft upholstered contour','SUBSURF');mod.levels=2
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    for f in o.data.polygons:f.use_smooth=True
    return o
def label(body,p,size=.08,mat=ink):return text('Original personal lettering',body,(p[0],-p[2],p[1]),size,mat)
def clear_objects():
    for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
# Openable entrance is exported separately; shell has real openings.
b('Floor structure',(0,-.1,0),(12,.2,10),walnut)
for x in range(24):
    for z in range(5):b('Individual oak floorboard',(-5.75+x*.5,.015,-4+z*2),(.488,.035,1.985),oak,.006)
b('Flat insulated roof',(0,3.32,0),(12.4,.22,10.4),metal)
b('Interior ceiling',(0,3.1,0),(12,.2,10),plaster)
b('Continuous roof fascia',(0,3.15,0),(12.1,.18,10.1),plaster)
for x in [-6,6]:b('Exterior rendered return',(x,1.55,0),(.22,3.1,10),plaster)
b('Rear masonry wall',(0,1.55,-5),(12,3.1,.22),plaster)
for x in [-3.65,3.65]:
    b('Front window apron',(x,.45,5),(4.7,.9,.22),plaster)
    b('Front window head',(x,2.85,5),(4.7,.6,.22),plaster)
    b('Residential glass',(x,1.85,5),(4.3,1.75,.055),glass,.008)
    for dx in [-2.2,0,2.2]:b('Window timber mullion',(x+dx,1.85,5.03),(.065,1.9,.09),oak,.008)
    for y in [.91,2.8]:b('Window sill reveal',(x,y,5.05),(4.5,.08,.24),oak,.008)
for x in [-1.12,1.12]:b('Entrance jamb',(x,1.36,5),(.16,2.72,.26),oak)
b('Door transom',(0,2.91,5),(2.15,.5,.23),plaster)
for z in [-5,5]:b('Coving',(0,3.05,z),(12,.09,.12),cream,.01)
# Bedroom on the left, open doorway into living area.
for z,depth in [(-2.5,5),(4,2)]:b('Bedroom partition',(-.8,1.5,z),(.15,3,depth),plaster)
b('Bedroom door lintel',(-.8,2.75,1.5),(.18,.5,3),plaster)
for x in [-6,-.8]:b('Bedroom skirting',(x,.09,0),(.06,.18,9.7),oak,.01)
# Bathroom rear-right with a wide opening.
b('Bathroom partition',(4.15,1.5,-2.2),(3.7,3,.12),plaster)
b('Bathroom doorway pier',(.45,1.5,-2.2),(.9,3,.12),plaster)
b('Bathroom doorway lintel',(1.6,2.75,-2.2),(1.4,.5,.12),plaster)
b('Bathroom doorway return',(.9,1.5,-3.6),(.12,3,2.7),plaster)
export('environment/vale_home_shell.glb',source=True)
clear_objects()
# Recreate materials from preserved datablocks; reset removes objects, not materials.
# Bed has sprung frame, curved cushioned mattress, cloth-grid duvet and pillows.
b('Bed oak frame',(-3.5,.28,-.6),(2.25,.3,2.35),oak,.07)
b('Upholstered headboard',(-3.5,.87,-1.9),(2.35,1.2,.14),leather,.08)
soft('Mattress with rounded ticking',(-3.5,.53,-.6),(2.12,.35,2.2),linen)
verts=[];faces=[]
for iz in range(25):
    for ix in range(25):
        x=-4.65+ix*2.3/24;z=-1.4+iz*2.05/24
        y=.76+.022*math.sin(ix*1.1+iz*.35)+.015*math.sin(iz*.8)
        y-=max(0,abs(x+3.5)-.95)*1.2
        verts.append((x,-z,y))
for z in range(24):
    for x in range(24):
        i=z*25+x;faces.append((i,i+1,i+26,i+25))
mesh('Draped folded quilt',verts,faces,cloth)
for x in [-4.03,-2.98]:soft('Linen sleeping pillow',(x,.81,-1.47),(.92,.20,.42),linen)
for x in [-5.1,-1.9]:
    b('Bedside cabinet',(x,.34,-1.5),(.62,.65,.64),walnut)
    b('Drawer face',(x,.40,-1.16),(.55,.23,.045),oak,.012)
    tube('Drawer brass pull',(x-.12,.40,-1.11),(x+.12,.40,-1.11),.014,brass)
    b('Lamp foot',(x,.72,-1.5),(.24,.05,.24),brass)
    tube('Lamp stem',(x,.73,-1.5),(x,1.03,-1.5),.017,metal)
    soft('Fabric lamp shade',(x,1.12,-1.5),(.34,.3,.34),lamp)
for x in [-5.3,-4.4]:
    b('Wardrobe panel',(x,1.12,-4.42),(.85,2.2,.65),walnut)
    for y in [.3,1.9]:b('Wardrobe inset rail',(x,y,-4.07),(.76,.035,.035),oak)
    tube('Wardrobe handle',(x+.27,1,-4.03),(x+.27,1.22,-4.03),.014,brass)
# Living room: upholstered sofa and stitched cushions.
b('Sofa frame',(3.6,.31,2.4),(2.9,.4,1),walnut,.09)
soft('Sofa back',(3.6,.83,2.85),(2.9,.95,.28),leather)
for x in [2.19,5.01]:soft('Rolled armrest',(x,.66,2.4),(.28,.67,1.05),leather)
for x in [2.7,3.6,4.5]:
    soft('Separate seat cushion',(x,.59,2.36),(.84,.23,.86),leather)
    soft('Back cushion',(x,.99,2.75),(.85,.65,.2),linen)
for x in [2.1,5.1]:
    for z in [2,2.8]:b('Sofa tapered foot',(x,.12,z),(.11,.24,.12),metal)
b('Coffee table top',(3.4,.46,.7),(2.1,.08,.85),oak,.07)
for x in [2.5,4.3]:
    for z in [.42,.98]:tube('Coffee table leg',(x,.04,z),(x,.43,z),.025,metal)
for i in range(4):b('Personal paperback',(3.7,.52+i*.028,.7),(.48,.025,.32),[cloth,paper,leather,paper][i],.004)
b('Envelope from Mara',(2.8,.515,.68),(.32,.009,.22),paper,.001)
label('MARA / DO NOT LOSE',(2.8,.524,.68),.033)
# Kitchen: cabinet inset doors, handles, backsplash, range and sculpted sink.
for x in [2.5,3.4,4.3,5.2]:
    b('Kitchen base cabinet',(x,.45,-1.48),(.86,.9,1.1),oak)
    b('Recessed kitchen door',(x,.46,-.91),(.76,.72,.04),walnut,.012)
    tube('Kitchen pull',(x-.15,.72,-.86),(x+.15,.72,-.86),.012,brass)
    b('Upper cabinet',(x,2.1,-1.75),(.86,.86,.55),oak)
b('Honed stone counter',(3.85,.96,-1.48),(3.75,.09,1.2),cream)
b('Backsplash',(3.85,1.3,-2.1),(3.75,.65,.06),cream,.01)
for x in [2.5,2.9]:
    for z in [-1.3,-1.7]:
        bpy.ops.mesh.primitive_torus_add(major_radius=.12,minor_radius=.012,location=(x,-z,1.02))
        finish(bpy.context.object,metal)
# Elliptical sink basin modeled as nested rings instead of a solid block.
v=[];f=[]
for r,y in [(1,.995),(.92,.99),(.68,.79),(.15,.77)]:
    for i in range(40):
        a=i*2*math.pi/40;v.append((3.7+.42*r*math.cos(a),1.48+.28*r*math.sin(a),y))
for ring in range(3):
    for i in range(40):a=ring*40+i;b0=ring*40+(i+1)%40;f.append((a,b0,b0+40,a+40))
mesh('Recessed ceramic sink basin',v,f,cream)
tube('Tap riser',(3.7,1,-1.88),(3.7,1.33,-1.88),.022,brass)
tube('Tap spout',(3.7,1.33,-1.88),(3.7,1.33,-1.65),.022,brass)
for x in [4.7,5.1]:
    cyl('Coffee mug',(x,1.11,1.3),.07,.16,cream)
# Personal writing desk and household props.
b('Writing desk',(-3.5,.77,3.9),(2.5,.09,.85),oak)
for x in [-4.5,-2.5]:
    for z in [3.6,4.15]:tube('Desk leg',(x,.03,z),(x,.73,z),.025,metal)
b('Personal document',(-3.5,.825,3.85),(.42,.009,.30),paper,.001)
label('VEYRA / MARA VALE',(-3.5,.836,3.85),.04)
b('Phone charger',(-2.65,.84,3.8),(.12,.045,.08),ink)
for j in range(4):tube('Charger cable',(-2.65-j*.08,.83,3.8+j*.03),(-2.73-j*.08,.83,3.83+j*.03),.004,ink)
for i in range(3):
    bpy.ops.mesh.primitive_torus_add(major_radius=.025,minor_radius=.004,location=(-3.9+i*.03,-3.7,.84));finish(bpy.context.object,brass)
b('Storage chest',(-5.25,.35,2.65),(.85,.7,1.1),walnut,.05)
for z in [2.3,3]:b('Chest strap',(-5.25,.35,z),(.87,.72,.035),metal,.007)
# Bathroom toilet is a rounded modeled fixture with separate seat/tank.
soft('Toilet pedestal',(4.6,.25,-4),(.43,.5,.56),cream)
soft('Toilet pan',(4.6,.53,-3.8),(.65,.22,.88),cream)
soft('Cistern',(4.6,.88,-4.4),(.7,.75,.23),cream)
b('Flush plate',(4.6,1.26,-4.4),(.16,.025,.07),brass)
b('Bathroom basin cabinet',(2.1,.46,-4.2),(1,.9,.65),walnut)
soft('Hand basin',(2.1,.96,-4.1),(1.05,.16,.7),cream)
b('Wall mirror',(2.1,1.75,-4.82),(.9,.95,.035),glass)
for j in range(5):b('Folded towel',(3,.06+j*.035,-4.5),(.6,.035,.4),linen,.014)
for x,z in [(5.3,4.15),(-5.3,4.2)]:
    cyl('Glazed plant pot',(x,-z,.25),.23,.5,cream)
    for j in range(9):
        a=j*2.4;end=(x+math.cos(a)*.32,.65+j*.075,z+math.sin(a)*.3)
        tube('Houseplant stem',(x,.48,z),end,.008,green)
        o=soft('Broad houseplant leaf',end,(.18,.035,.4),green);o.rotation_euler.z=a
export('environment/vale_home_furniture.glb',source=True)
clear_objects()
# Door pivot at the left hinge, geometry extends toward +X.
b('Paneled entrance door',(1.0,1.30,0),(1.96,2.6,.10),oak,.025)
for y in [.55,1.75]:b('Recessed door field',(1,y,-.06),(1.55,.8,.035),walnut,.012)
for x in [1.73]:tube('Door lever',(x,1.1,-.13),(x+.16,1.1,-.13),.018,brass)
export('environment/vale_home_door.glb',source=True)
