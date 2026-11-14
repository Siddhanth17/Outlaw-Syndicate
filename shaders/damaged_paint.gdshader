shader_type spatial;
uniform vec4 hits[12];
uniform vec4 paint : source_color = vec4(0.32,0.08,0.035,1.0);
varying vec3 rest_position;
void vertex() { rest_position = VERTEX; }
void fragment() {
 float wear = 0.0;
 for(int i=0;i<12;i++) {
  float d=distance(rest_position,hits[i].xyz);
  float mark=(1.0-smoothstep(0.12,0.7,d))*hits[i].w;
  float scrape=step(0.65,sin(rest_position.y*130.0+rest_position.z*22.0));
  wear=max(wear,mark*(0.35+scrape*0.65));
 }
 ALBEDO=mix(paint.rgb,vec3(0.15,0.17,0.18),clamp(wear,0.0,1.0));
 METALLIC=0.6;
 ROUGHNESS=mix(0.26,0.8,clamp(wear,0.0,1.0));
}
