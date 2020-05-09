#pragma language glsl3

uniform vec3 sun;
// uniform Image map;
uniform Image height_map;
uniform float preci = 1;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 texturecolor = Texel(tex, texture_coords);
	float h = Texel(height_map, texture_coords).x;
	// texturecolor.w = 1;
	//
	vec3 pos = vec3(texture_coords.x*1024.0, texture_coords.y*1024.0, h);
	vec3 LightDir = normalize(sun - pos);

	while(
			pos != sun
			&& pos.z < 1
		)
	{
		pos += LightDir*preci;

		// float LerpX = round(pos.x);
		// float LerpZ = round(pos.z);
		float c = Texel(height_map, vec2(mod(pos.x, 1024.0)/1024.0, mod(pos.y, 1024.0)/1024.0)).x;
		if(pos.z <= c) {

			// return vec4(1,0,0,1);
			return vec4(texturecolor.xyz*0.5, 1);
		}
	}
	return texturecolor;
}
