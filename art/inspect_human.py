import bpy
from pathlib import Path
root = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'art/source/camper-cc0.glb'))
for obj in bpy.context.scene.objects:
    print('OBJECT',obj.name,obj.type,tuple(obj.dimensions),tuple(obj.scale))
    if obj.type=='ARMATURE':
        print('BONES',[(b.name,tuple(b.head_local),tuple(b.tail_local)) for b in obj.data.bones])
for a in bpy.data.actions:
    print('ACTION',a.name,tuple(a.frame_range))
