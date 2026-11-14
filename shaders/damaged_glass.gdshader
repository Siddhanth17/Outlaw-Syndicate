shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform float stage = 0.0;
uniform vec2 origin = vec2(0.5);
void fragment() {
 vec2 p = UV - origin;
 float angle = atan(p.y, p.x);
 float ray = pow(abs(cos(angle * 9.0 + sin(angle * 13.0)*0.7)), 95.0);
 float ring = pow(abs(cos(length(p)*75.0 + sin(angle*7.0))), 30.0);
 float radius = stage < 1.5 ? 0.36 : 1.5;
 float cracks = max(ray, ring * 0.5) * step(length(p), radius) * step(0.5, stage);
 ALBEDO = mix(vec3(0.065,0.12,0.16), vec3(0.8,0.86,0.9), cracks);
 ROUGHNESS = 0.16 + cracks*0.65;
 METALLIC = 0.25;
 ALPHA = 0.25 + cracks*0.70;
}
