shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float wetness : hint_range(0.0,1.0) = 0.55;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 p=world_position.xz; vec2 uv=p/3.0;
 vec3 base=texture(albedo_map,uv).rgb;
 float repaired=step(0.79,hash(floor((p+vec2(2,0))/vec2(4,8))))*smoothstep(.03,.12,min(fract(p.x/4.0),1.0-fract(p.x/4.0)));
 float stains=smoothstep(.55,.80,noise(p*.43))*smoothstep(.3,.7,noise(p*1.7));
 float puddle=smoothstep(.61,.77,noise(p*.27+12.0))*wetness;
 float edge=smoothstep(5.8,8.0,abs(p.x));
 ALBEDO=base*mix(.60,.40,repaired)*mix(1.0,.55,stains)*mix(1.0,.72,puddle)+vec3(.026,.023,.018)*edge;
 ROUGHNESS=mix(clamp(texture(rough_map,uv).r*.8+.15,.45,.95),.14,puddle);
 METALLIC=0.0;
 NORMAL_MAP=texture(normal_map,uv).rgb;
 NORMAL_MAP_DEPTH=mix(.4,.10,puddle);
}
