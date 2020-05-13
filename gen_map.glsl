#pragma language glsl3

uniform Image biome;
uniform float dens=1.0;
uniform vec2 off = vec2(0.0, 0.0);


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
	// left: value noise
	mat2 m2 = mat2( 1.6,  1.2, -1.2,  1.6 );

	float h = 0.0;
	vec2 uv = (texture_coords+off)*dens;
	h += 0.5000*noise( uv ); uv = m2*uv;
	h += 0.2500*noise( uv ); uv = m2*uv;
	h += 0.1250*noise( uv ); uv = m2*uv;
	h += 0.0625*noise( uv ); uv = m2*uv;
	h += 0.03125*noise( uv ); uv = m2*uv;
	h += 0.015625*noise( uv ); uv = m2*uv;

	h =  0.2+h*1.6;
	h = pow(h, 1.001);

	// if (texture_coords.x > 0.45 && texture_coords.x < 0.55 && texture_coords.y > 0.45 && texture_coords.y < 0.55) {
	// 	return vec4(1,0,1, 1);
	// }
	// else {
	// 	vec3 c = Texel(biome, vec2(0.5, 0.5)).xyz;
	// 	return vec4(c, 0.5);
	// }


	float m = 0.0;
	uv = (texture_coords+off)/20.0*dens+vec2(13,70);
	m += 0.5*noise( uv ); uv = m2*uv;
	m += 0.2500*noise( uv ); uv = m2*uv;
	m += 0.1250*noise( uv ); uv = m2*uv;
	m += 0.0625*noise( uv ); uv = m2*uv;
	m += 0.03125*noise( uv ); uv = m2*uv;
	m += 0.015625*noise( uv ); uv = m2*uv;

	m =  0.1+m*1.3;

	float t = 0.0;
	uv = (texture_coords+off)/30.0*dens+vec2(-50,100);
	t += 0.5*noise(uv); uv = m2*uv;
	t += 0.1250*noise( uv ); uv = m2*uv;
	t += 0.0625*noise( uv ); uv = m2*uv;
	t += 0.03125*noise( uv ); uv = m2*uv;
	t += 0.015625*noise( uv ); uv = m2*uv;

	t =0.5+t*1.6;
	// t -= 0.5;
	// t *= 0.05;

	vec4 c;

	if (h <= 0.091) {
		c = vec4(0, 107.0/255.0, 187/255.0, 0.091); // water
		h = 0.091;
	}
	else if (h < 0.091+0.015)
		c = vec4(1.0, 200.0/255.0, 114.0/255.0, 0.091); // water
	else
		c = Texel(biome, vec2(m, t-(h*0.3)));

	c += vec4(vec3(noise(texture_coords*400.0*dens)*0.04), 0);

	return vec4(c.xyz*(0.50+h/2.0), h);
}
