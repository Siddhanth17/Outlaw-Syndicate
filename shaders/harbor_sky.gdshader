shader_type sky;
void sky(){
 vec3 horizon=vec3(.024,.034,.047);
 vec3 zenith=vec3(.002,.005,.013);
 float elevation=smoothstep(0.0,.75,max(EYEDIR.y,0.0));
 COLOR=mix(horizon,zenith,elevation);
 if(EYEDIR.y<0.0) COLOR=mix(horizon,vec3(.006,.008,.010),smoothstep(0.0,.4,-EYEDIR.y));
}
