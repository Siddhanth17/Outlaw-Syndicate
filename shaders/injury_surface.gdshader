shader_type spatial;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D roughness_map : filter_linear_mipmap_anisotropic;
uniform bool use_roughness_map=false;
uniform int roughness_channel=0;
uniform float base_roughness = 0.65;
uniform vec4 marks[4];
uniform float mark_units_per_meter=1.0;
varying vec3 surface_position;
void vertex(){ surface_position=VERTEX; }
void fragment(){
 vec3 color=texture(albedo_map,UV).rgb*tint.rgb;
 for(int i=0;i<4;i++){
  float distance_to_hit=distance(surface_position,marks[i].xyz)/mark_units_per_meter;
  float bruise=(1.0-smoothstep(0.025,0.12,distance_to_hit))*marks[i].w;
  float stain=(1.0-smoothstep(0.012,0.055,distance_to_hit))*marks[i].w;
  color=mix(color,color*vec3(0.65,0.48,0.56),bruise*0.6);
  color=mix(color,vec3(0.13,0.018,0.012),stain*0.45);
 }
 ALBEDO=color;
 ROUGHNESS=base_roughness;
 if(use_roughness_map){vec4 rough=texture(roughness_map,UV);ROUGHNESS*=rough[clamp(roughness_channel,0,3)];}
}
