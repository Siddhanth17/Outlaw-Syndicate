shader_type spatial;
render_mode cull_disabled;
uniform float strength = 0.8;
varying vec2 cloth_uv;
void vertex(){
 cloth_uv=UV;
 float free_edge=UV.x*UV.x;
 VERTEX.z+=sin(TIME*2.1+UV.x*4.0)*.10*strength*free_edge;
 VERTEX.y+=sin(TIME*1.7+UV.x*6.0)*.025*strength*free_edge;
}
void fragment(){
 float stripe=step(.82,fract(cloth_uv.y*6.0));
 ALBEDO=mix(vec3(.19,.25,.27),vec3(.52,.43,.24),stripe);
 ROUGHNESS=.9;
}
