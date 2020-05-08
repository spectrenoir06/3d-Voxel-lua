#pragma language glsl3

uniform vec3 sun;
uniform Image map;
uniform Image height_map;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 texturecolor = Texel(map, texture_coords);
	float h = Texel(height_map, texture_coords).x;
	// texturecolor.w = 1;
	//
	vec3 pos = vec3(texture_coords.x*1024.0, h, texture_coords.y*1024.0);
	vec3 LightDir = normalize(sun - pos);

	while( 	pos.x >=0
			&& pos.x < 1024
			&& pos.z >=0
			&& pos.z < 1024
			&& pos != sun
			&& pos.y < 1
		)
	{
		pos += LightDir;

		// float LerpX = round(pos.x);
		// float LerpZ = round(pos.z);
		float c = Texel(height_map, vec2(pos.x/1024.0, pos.z/1024.0)).x;
		if(pos.y <= c) {

			// return vec4(1,0,0,1);
			return vec4(texturecolor.xyz*0.5, 1);
		}
	}
	return texturecolor;
}
