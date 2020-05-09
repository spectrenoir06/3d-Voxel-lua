#pragma language glsl3

uniform Image biome;
uniform float Utime=0;
uniform float dens=1.0;
uniform float preci=1.0;
uniform vec3 sun;


vec2 hash( vec2 p ) // replace this by something better
{
	p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
	const float K1 = 0.366025404; // (sqrt(3)-1)/2;
	const float K2 = 0.211324865; // (3-sqrt(3))/6;

	vec2  i = floor( p + (p.x+p.y)*K1 );
	vec2  a = p - i + (i.x+i.y)*K2;
	float m = step(a.y,a.x);
	vec2  o = vec2(m,1.0-m);
	vec2  b = a - o + K2;
	vec2  c = a - 1.0 + 2.0*K2;
	vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
	return dot( n, vec3(70.0) );
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{

	float f = 0.0;

	// left: value noise
	{
		texture_coords *= dens;
		texture_coords += vec2(Utime, 0.0);
		mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
		f  = 0.5000*noise( texture_coords ); texture_coords = m*texture_coords;
		f += 0.2500*noise( texture_coords ); texture_coords = m*texture_coords;
		f += 0.1250*noise( texture_coords ); texture_coords = m*texture_coords;
		f += 0.0625*noise( texture_coords ); texture_coords = m*texture_coords;
		f += 0.03125*noise( texture_coords ); texture_coords = m*texture_coords;
		f += 0.015625*noise( texture_coords ); texture_coords = m*texture_coords;
	}

	f =  0.3+f*1.5;
	vec4 c = Texel(biome, vec2(0.5,1-f));
	c += vec4(vec3(noise(texture_coords*8.0)*0.02), 0);


	return vec4(c.xyz, f);
}
