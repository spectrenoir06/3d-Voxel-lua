#pragma language glsl3

uniform vec3 sun;
uniform float preci = 0.001;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 texturecolor = Texel(tex, texture_coords);
	float h = texturecolor.w;

	vec3 pos = vec3(texture_coords.x, texture_coords.y, h);
	vec3 LightDir = normalize(sun);


	// if (sun.z <= 0.01)
	// 	return vec4(texturecolor.xyz*0.7, h);

	// return vec4(pos.z, 0, 0, h);

	while (pos.z < 1 && pos.x >= 0 && pos.x < 1 && pos.y >= 0 && pos.y < 1 )
	{
		pos += LightDir*preci;
		float c = Texel(tex, mod(pos.xy, 1.0)).w;
		if(pos.z <= c)
			return vec4(texturecolor.xyz*0.7, h);
	}
	return texturecolor;
}
