"""Separate a real hinged front-left door from the preserved original Sable.

No original GLB is overwritten. Rest damage meshes stay individually addressable.
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import *
import bmesh
reset()
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/vehicles/sable_body.glb'))
for o in list(bpy.context.scene.objects):
    if o.type!='MESH':continue
    world=o.matrix_world.copy();o.parent=None;o.matrix_world=world
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
hinge=bpy.data.objects.new('DriverDoorHinge',None);bpy.context.collection.objects.link(hinge)
hinge.location=(-.84,-.80,.78)
leaves=[]
for obj in list(bpy.context.scene.objects):
    if obj.type!='MESH':continue
    if obj.name.startswith('Side glass left front') or obj.name.startswith('Side mirror') and obj.data.vertices and sum(v.co.x for v in obj.data.vertices)/len(obj.data.vertices)<0:
        leaves.append(obj);continue
    if 'glass' in obj.name or obj.name in ['Windshield','Rear screen']:continue
    bm=bmesh.new();bm.from_mesh(obj.data)
    for coordinate,normal in [((0,-.80,0),(0,1,0)),((0,.23,0),(0,1,0)),((-.72,0,0),(1,0,0)),((0,0,.32),(0,0,1))]:
        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=coordinate,plane_no=normal)
    bm.to_mesh(obj.data);bm.free()
    chosen=[]
    for f in obj.data.polygons:
        c=sum((obj.data.vertices[v].co for v in f.vertices),Vector())/len(f.vertices)
        if c.x<-.72 and -.8001<c.y<.2301 and .3199<c.z<1.40:chosen.append(f.index)
    if not chosen:continue
    leaf=obj.copy();leaf.data=obj.data.copy();bpy.context.collection.objects.link(leaf);leaf.name='Driver door leaf / '+obj.name
    for target,keep in [(obj,False),(leaf,True)]:
        bm=bmesh.new();bm.from_mesh(target.data);bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[f for f in bm.faces if (f.index in chosen)!=keep],context='FACES')
        loose=[v for v in bm.verts if not v.link_faces]
        if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
        bm.to_mesh(target.data);bm.free()
    leaves.append(leaf)
inner=material('Driver door / inner padded trim',(.03,.034,.036),rough=.8)
leaves.append(box('Driver door inner panel',(-.76,-.28,.59),(.035,.94,.35),inner,.025))
for obj in leaves:
    world=obj.matrix_world.copy();obj.parent=hinge;obj.matrix_world=world
assert len(leaves)>=3,'No actual separated door geometry'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/sable_interactive.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/vehicles/sable_interactive.glb'),export_format='GLB',export_animations=False,export_cameras=False,export_lights=False)
print('HINGED_DOOR_EXPORTED',len(leaves))
