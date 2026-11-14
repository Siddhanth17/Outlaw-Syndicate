shader_type spatial;
uniform vec4 paint : source_color = vec4(.22,.27,.25,1);
uniform float age = .5;
varying vec3 world_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(42.3,71.7)))*43758.5453);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;}
void fragment(){
 vec3 p=world_position;
 float spots=hash(floor(p.xz*14.0+p.y*1.3));
 float streak=hash(floor(p.xz*5.0));
 float rust=smoothstep(.81,1.0,spots)*age+step(.94,streak)*(.4+.4*sin(p.y*.9))*age;
 float dirt=1.0-smoothstep(0.0,1.8,p.y);
 ALBEDO=mix(paint.rgb,vec3(.22,.09,.035),clamp(rust,0.0,.8))*(1.0-dirt*.35);
 ROUGHNESS=clamp(.45+age*.25+rust*.2,.35,.95);
 METALLIC=.42*(1.0-clamp(rust,0.0,1.0));
}
