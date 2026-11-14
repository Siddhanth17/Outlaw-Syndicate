shader_type sky;
uniform float daylight : hint_range(0.0,1.0) = 0.0;
void sky(){
 vec3 horizon=vec3(.024,.034,.047);
 vec3 zenith=vec3(.002,.005,.013);
 float elevation=smoothstep(0.0,.75,max(EYEDIR.y,0.0));
 COLOR=mix(mix(horizon,zenith,elevation),mix(vec3(.55,.68,.78),vec3(.12,.34,.62),elevation),daylight);
 if(EYEDIR.y<0.0) COLOR=mix(horizon,vec3(.006,.008,.010),smoothstep(0.0,.4,-EYEDIR.y));
}
