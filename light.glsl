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
	vec3 pos = vec3(texture_coords.x, texture_coords.y, h);
	vec3 LightDir = normalize(sun - pos);

	if (sun.z <= 0.01)
		return vec4(texturecolor.xyz*0.5, 1);

	while (pos.z < 1)
	{
		pos += LightDir*preci;
		float c = Texel(height_map, mod(pos.xy, 1.0)).x;
		if(pos.z <= c)
			return vec4(texturecolor.xyz*0.5, 1);
	}
	return texturecolor;
}
