shader_type spatial;
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1)).xyz; }
void fragment(){
 vec2 cell=floor(world_position.xy/vec2(1.1,1.8));
 float h=fract(sin(dot(cell,vec2(12.9,78.2)))*43758.5);
 vec2 pane=fract(world_position.xy/vec2(1.1,1.8));
 float windows=step(.65,h)*step(.25,pane.x)*step(pane.x,.7)*step(.25,pane.y)*step(pane.y,.65);
 ALBEDO=vec3(.025,.035,.045);
 EMISSION=vec3(.23,.16,.08)*windows*.7;
 ROUGHNESS=.85;
}
