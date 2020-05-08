#pragma language glsl3

uniform vec3 sun;
uniform Image map;
uniform Image height_map;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 texturecolor = Texel(tex, texture_coords);
	float h = Texel(height_map, texture_coords).x;
	// texturecolor.w = 1;
	//
	vec3 pos = vec3(texture_coords.x*1024.0, texture_coords.y*1024.0, h);
	vec3 LightDir = vec3(sun - pos);
	vec3 L = normalize(LightDir);
	float Dist = length(LightDir);


	for (float i = 0.0; i < Dist; i++) {
		vec3 tmp = pos + L * i;

		if (tmp.x >= 0
				&& tmp.x < 1024
				&& tmp.y >=0
				&& tmp.y < 1024
				// && tmp != sun
				// && tmp.z < 1
		) {
			float c = Texel(height_map, vec2(tmp.x/1024.0, tmp.y/1024.0)).x;
			// return vec4(vec3(tmp.z,c,0), 1);
			if(tmp.z < c) {
				return vec4(texturecolor.xyz*0.5, 1);
			}
		} else {
			// return vec4(vec3(i), 1);
		}
	}
	return texturecolor;
}
