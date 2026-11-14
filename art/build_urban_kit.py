"""Original Veyra street architecture. Blender 4.5 -> GLB; no external models.
Meters, -Y facade front, Z up. Street shells have recessed commercial bays,
separate floor/wall geometry and intentionally accessible shop vestibules.
"""
import sys, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *

def prepare_surfaces():
    # Preserve the authored tint when an image drives the shader base color.
    for mat in bpy.data.materials:
        if not mat.use_nodes: continue
        bs=mat.node_tree.nodes.get('Principled BSDF')
        if not bs: continue
        links=list(bs.inputs['Base Color'].links)
        if links:
            source=links[0].from_socket
            mat.node_tree.links.remove(links[0])
            tint=mat.node_tree.nodes.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY'
            tint.inputs[0].default_value=1;tint.inputs[2].default_value=mat.diffuse_color
            mat.node_tree.links.new(source,tint.inputs[1]);mat.node_tree.links.new(tint.outputs[0],bs.inputs['Base Color'])
    # Meter-based planar mapping avoids stretching one concrete tile over a facade.
    for obj in bpy.context.scene.objects:
        if obj.type!='MESH':continue
        uv=obj.data.uv_layers.new(name='Meters') if not obj.data.uv_layers else obj.data.uv_layers.active
        for face in obj.data.polygons:
            n=face.normal;axis=max(range(3),key=lambda i:abs(n[i]));axes=[i for i in range(3) if i!=axis]
            for loop in face.loop_indices:
                point=obj.matrix_world@obj.data.vertices[obj.data.loops[loop].vertex_index].co
                uv.data[loop].uv=(point[axes[0]]/2,point[axes[1]]/2)

for variant in range(4):
    reset()
    stone=material('Cut limestone',(.38,.35,.29),rough=.82,texture='concrete_diff.jpg',normal='concrete_normal.jpg')
    wall=material('Brick ceramic' if variant%2==0 else 'Mineral stucco',[(.28,.095,.055),(.31,.33,.29),(.20,.12,.08),(.42,.36,.26)][variant],rough=.84,texture='concrete_diff.jpg',normal='concrete_normal.jpg')
    metal=material('Anodized frames',(.032,.047,.052),.7,.38)
    glass=material('Opaque reflective tinted glazing',(.045,.10,.13),.68,.16)
    warm=material('Occupied warm window',(.57,.34,.14),rough=.45,emission=.6)
    dark=material('Interior shadow',(.026,.031,.033),rough=.94)
    wood=material('Oiled timber',(.13,.065,.028),rough=.64)
    awning=material('Woven awning',[(.035,.14,.12),(.24,.06,.035),(.11,.10,.20),(.28,.20,.06)][variant],rough=.92)
    height=10.8+variant*3.1
    # Ground-floor open vestibule: walls have an actual entrance rather than a painted door.
    box('Terrazzo plinth',(0,0,.10),(18,18,.20),stone)
    box('Rear party wall',(0,8.8,height/2),(18,.4,height),wall)
    for x in [-8.8,8.8]:
        box('Corner masonry return',(x,0,height/2),(.4,18,height),wall)
    box('Upper facade backing',(0,-8.65,(height+3.4)/2),(18,.42,height-3.4),wall)
    box('Shop rear wall',(0,-4.5,1.6),(17.6,.25,3.2),wood)
    for x in [-8.65,-3,3,8.65]:
        box('Stone shop pier',(x,-8.85,1.65),(.45,.5,3.3),stone,.045)
    for x in [-5.8,5.8]:
        # Window bay; central 2.2m entrance stays open for walking inside.
        box('Shop window sill',(x,-8.8,.38),(5.1,.40,.62),stone)
        box('Storefront glazing',(x,-8.90,1.88),(5.05,.065,2.15),glass,.01)
        for dx in [-2.5,0,2.5]: box('Storefront mullion',(x+dx,-8.96,1.9),(.055,.09,2.5),metal,.008)
        box('Display counter',(x,-6.7,.6),(3.8,1.0,1.15),wood,.06)
        for dx in [-1.25,0,1.25]:
            box('Display stock',(x+dx,-6.7,1.3),(.5,.5,.3),awning,.04)
    for x in [-1.2,1.2]:box('Entrance jamb',(x,-8.95,1.45),(.12,.22,2.9),metal,.015)
    box('Entrance transom',(0,-8.95,2.9),(2.5,.22,.15),metal)
    box('Shop fascia',(0,-9.02,3.12),(17.7,.24,.55),awning)
    text('Business identity',['MORROW / BOOKS','LANTERN / CAFE','VEYRA / CYCLEWORKS','NORTHLINE / GOODS'][variant],(0,-9.18,3.02),.43,warm)
    # Cantilevered cloth canopy with visible edging and brackets.
    box('Canopy',(0,-9.65,2.75),(17.4,1.7,.10),awning)
    box('Canopy valance',(0,-10.45,2.61),(17.4,.07,.28),awning)
    for x in [-7,0,7]:beam('Canopy bracket',(x,-8.9,2.2),(x,-10.3,2.72),.025,metal)
    # Real window reveals, sills, lintels, framing and varied occupied panes.
    floors=int((height-3.6)/3.1)
    for floor in range(floors):
        z=5.0+floor*3.1
        box('String course',(0,-8.99,z-1.15),(18,.23,.16),stone)
        for col,x in enumerate([-6.6,-3.3,0,3.3,6.6]):
            box('Recessed window',(x,-8.91,z),(1.7,.06,1.85),warm if (col+floor*3+variant)%5==0 else glass,.01)
            for dx in [-.93,.93]:box('Window reveal',(x+dx,-9.02,z),(.16,.30,2.1),stone,.02)
            box('Projecting sill',(x,-9.12,z-1.0),(2.15,.52,.15),stone,.025)
            box('Stone lintel',(x,-9.04,z+1.01),(2.1,.30,.16),stone)
            box('Center mullion',(x,-9.06,z),(.05,.08,1.9),metal,.005)
            box('Window crossbar',(x,-9.06,z-.16),(1.75,.08,.05),metal,.005)
            if variant==1 and floor==0 and col%2==0:
                box('Balcony slab',(x,-9.65,z-1.08),(2.5,1.45,.15),stone)
                beam('Balcony rail',(x-1.2,-10.3,z-.10),(x+1.2,-10.3,z-.10),.027,metal)
                for k in range(9):beam('Baluster',(x-1.2+k*.3,-10.3,z-1),(x-1.2+k*.3,-10.3,z-.10),.014,metal)
        # Side elevations hold up at intersections; recessed frames, not flat random squares.
        for side in [-1,1]:
            for y in [-5,0,5]:
                box('Side window',(side*9.02,y,z),(.06,1.8,1.85),glass,.01)
                for dy in [-1,1]:box('Side jamb',(side*9.08,y+dy,z),(.20,.13,2.1),stone)
                box('Side sill',(side*9.14,y,z-1),(.38,2.2,.15),stone)
    box('Roof coping',(0,0,height+.1),(18.7,18.7,.28),stone)
    box('Roof membrane',(0,0,height+.27),(17.9,17.9,.10),dark)
    for x in [-8.9,8.9]:box('Parapet',(x,0,height+.6),(.25,18,1),stone)
    for y in [-8.9,8.9]:box('Parapet',(0,y,height+.6),(18,.25,1),stone)
    for x in [-5,4]:
        box('Rooftop HVAC',(x,3,height+.9),(2.3,1.7,1.2),metal,.08)
        for k in range(8):box('Vent louvers',(x-1+k*.28,2.1,height+.9),(.10,.08,.8),dark,.005)
        cyl('Exhaust stack',(x,4,height+1.8),.18,1.8,metal)
    for x in [-8.2,8.2]:beam('Rainwater downpipe',(x,-9.15,.3),(x,-9.15,height),.055,metal)
    # Facade masonry bands with staggered joints produce real relief at street level.
    if variant%2==0:
        for row in range(int((height-3.5)/.28)):
            z=3.5+row*.28
            for x in [-8.2,8.2]:
                box('Masonry bond',(x+(.12 if row%2 else -.12),-8.91,z),(.65,.045,.24),wall,.008)
    prepare_surfaces()
    export('environment/urban_frontage_%d.glb'%variant,True)

# Reusable modeled street furniture, not debug fixtures.
reset()
metal=material('Graphite street steel',(.04,.055,.06),.7,.44)
wood=material('Weathered bench timber',(.19,.095,.035),rough=.8)
stone=material('Cast concrete',(.32,.33,.30),rough=.92,texture='concrete_diff.jpg',normal='concrete_normal.jpg')
for x in [-.8,.8]:
    beam('Bench leg',(x,0,0),(x,0,.45),.045,metal)
    beam('Back support',(x,.22,.15),(x,.28,.95),.035,metal)
for j in range(5): box('Seat slat',(0,-.22+j*.11,.48),(2.0,.085,.055),wood,.015)
for z in [.65,.8,.95]:box('Backrest slat',(0,.27,z),(2,.06,.10),wood,.015)
export('environment/urban_bench.glb',True)
reset()
concrete=material('Barrier concrete',(.42,.41,.37),rough=.9,texture='concrete_diff.jpg',normal='concrete_normal.jpg')
# Extruded tapered jersey profile rather than a box roadblock.
profile=[(-.38,0),(.38,0),(.38,.17),(.15,.55),(.13,.95),(-.13,.95),(-.15,.55),(-.38,.17)]
verts=[(x,y,z) for y in [-2,2] for x,z in profile]
faces=[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
mesh('Jersey safety barrier',verts,faces,concrete)
prepare_surfaces()
export('environment/urban_barrier.glb',True)
reset()
bark=material('Plane tree bark',(.12,.085,.052),rough=.96)
leaf=material('Plane tree leaves',(.065,.19,.045),rough=.87)
beam('Branching trunk',(0,0,0),(.12,.08,4.2),.16,bark)
vertices=[];faces=[]
for branch in range(14):
    angle=branch*2.39996
    end=Vector((math.cos(angle)*(1.4+branch%3*.3),math.sin(angle)*(1.4+branch%3*.3),3.3+branch%5*.45))
    beam('Crown branch',(.08,0,2.2+branch%4*.3),end,.035,bark)
    for j in range(55):
        center=end+Vector((random.uniform(-.8,.8),random.uniform(-.8,.8),random.uniform(-.55,.65)))
        normal=Vector((random.uniform(-1,1),random.uniform(-1,1),random.uniform(.2,1))).normalized()
        u=normal.cross(Vector((0,1,0))).normalized()*.15
        v=normal.cross(u).normalized()*.25
        start=len(vertices)
        vertices += [center-v,center+u-v*.25,center+u*.75+v*.5,center+v,center-u*.75+v*.5,center-u-v*.25]
        faces.append(tuple(start+k for k in range(6)))
        faces.append(tuple(start+k for k in range(5,-1,-1)))
mesh('Individual leaf canopy',vertices,faces,leaf)
export('environment/urban_tree.glb',True)
reset()
steel=material('Signal powdercoat',(.025,.032,.035),.55,.5)
beam('Signal post',(0,0,0),(0,0,4.5),.055,steel)
box('Signal housing',(0,-.07,4.2),(.40,.28,1.12),steel,.065)
for name,z,color in [('red',4.55,(.8,.018,.01)),('amber',4.2,(.8,.38,.015)),('green',3.85,(.025,.7,.14))]:
    lens=material('Signal '+name,color,rough=.25,emission=1)
    cyl('Recessed '+name+' lens',(0,-.225,z),.125,.035,lens,(math.pi/2,0,0),32)
    box('Lens sun visor',(0,-.30,z+.15),(.32,.30,.035),steel,.008)
export('environment/urban_signal.glb',True)
print('URBAN_KIT_COMPLETE')
