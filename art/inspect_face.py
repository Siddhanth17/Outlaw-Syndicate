import bpy,json
from mathutils import Matrix
bpy.ops.wm.open_mainfile(filepath='D:/OutlawSyndicate/art/source/adrian.blend')
a=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
a.animation_data.action=None
for b in a.pose.bones:b.matrix_basis=Matrix.Identity(4)
o=next(o for o in bpy.context.scene.objects if o.type=='MESH')
for z in [1.52,1.54,1.56,1.58,1.60,1.62,1.64,1.66,1.68]:
 p=[o.matrix_world@v.co for v in o.data.vertices if abs((o.matrix_world@v.co).z-z)<.005 and abs((o.matrix_world@v.co).x)<.06]
 print('FACE',z,'front',min(v.y for v in p) if p else None)
print('HEAD',a.data.bones['Head'].head_local[:])
