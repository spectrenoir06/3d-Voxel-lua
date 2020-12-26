// g++ main.cpp `pkg-config --cflags --libs sdl2`
#include <SDL2/SDL.h>
#include "SDL2/SDL_image.h"
#include <iostream>
#include <iomanip>
#include <vector>
#include <cstring>

#define max(a,b) \
({ __typeof__ (a) _a = (a); \
	__typeof__ (b) _b = (b); \
	_a > _b ? _a : _b; })

#define min(a,b) \
({ __typeof__ (a) _a = (a); \
	__typeof__ (b) _b = (b); \
	_a < _b ? _a : _b; })

int mod(int a, int b)
{
	int r = a % b;
	return r < 0 ? r + b : r;
}

#define WIN_X 1280
#define WIN_Y 720

#define map_size 4096

SDL_Surface* text_surface;
SDL_Surface* height_surface;

uint32_t *text_data;
uint8_t *height_data;
uint32_t *screen_data;

uint32_t anim_text = 0;

uint32_t ybuffer[WIN_X];

void render(float px, float py, float r, float h, float vx, float vy, uint dist, uint lx, uint ly) {
	// printf("px = %f,\npy = %f,\nr = %f,\nh = %f,\nvx = %f,\nvy = %f,\ndist = %d\n\n",
	// 	px, 
	// 	py, 
	// 	r, 
	// 	h, 
	// 	vx, 
	// 	vy,
	// 	dist
	// );

	memset(screen_data, 0x00, WIN_X*WIN_Y*4);

	float sinphi = sin(r);
	float cosphi = cos(r);
	float dz = 1.0;

	for (int i=0; i < WIN_X; i++)
		ybuffer[i] = ly;
	
	float z = 1.0;

	uint32_t off = map_size * map_size * anim_text;

	while (z < dist) {
		float pleft_x = (-cosphi*z - sinphi*z) + px;
		float pleft_y = ( sinphi*z - cosphi*z) + py;


		float pright_x = ( cosphi*z - sinphi*z) + px;
		float pright_y = (-sinphi*z - cosphi*z) + py;

		float dx = (pright_x - pleft_x) / WIN_X;
		float dy = (pright_y - pleft_y) / WIN_X;

		for (int x=0; x < WIN_X; x++) {
			int32_t pos = mod(pleft_x, map_size) + mod(pleft_y, map_size) * map_size;
			uint32_t height = text_data[pos]>>24;
			int32_t height_on_screen = max((h - height) / z * vx + vy, 0);

			height_on_screen = min(height_on_screen, WIN_Y);
			// height_on_screen = max(height_on_screen, 0);

			for (int y=height_on_screen; y < ybuffer[x]; y++)
				screen_data[x + y * WIN_X] = text_data[pos+off] | 0xff000000;

			if (height_on_screen < ybuffer[x])
				ybuffer[x] = height_on_screen;

			pleft_x += dx;
			pleft_y += dy;
		}
		z += dz;
		if (z > 300)
			dz = dz + 0.05;
	}
}

int32_t pos_x = 4096/2;
int32_t pos_y = 4096/2;
float pos_r = 0;
int32_t pos_h = 200;

int32_t vx = 0;
int32_t vy = 0;

int32_t dist = 0;


int main(int argc, char** argv) {
	SDL_Init(SDL_INIT_EVERYTHING);

	SDL_Window* window = SDL_CreateWindow(
		"SDL2",
		SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
		WIN_X, WIN_Y,
		SDL_WINDOW_SHOWN
	);

	SDL_Renderer* renderer = SDL_CreateRenderer(
		window,
		-1,
		SDL_RENDERER_ACCELERATED
	);

	text_surface = IMG_Load("test.png");
	text_data = (uint32_t*)text_surface->pixels;

	// height_surface = IMG_Load("C1W_HEIGHT.png");
	// height_data = (uint8_t*)height_surface->pixels;

	std::cout << SDL_GetPixelFormatName(text_surface->format->format) << std::endl;

	SDL_Texture* texture = SDL_CreateTexture (
		renderer,
		SDL_PIXELFORMAT_ABGR8888,
		SDL_TEXTUREACCESS_STREAMING,
		WIN_X, WIN_Y
	);

	// std::vector< unsigned char > pixels(texWidth * texHeight * 4, 0);
	screen_data = (uint32_t*)malloc(map_size*map_size*4);


	SDL_Event event;
	bool running = true;
	bool useLocktexture = false;

	unsigned int frames = 0;
	Uint64 start = SDL_GetPerformanceCounter();
	Uint64 anim_start = SDL_GetPerformanceCounter();

	while (running) {

		SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
		SDL_RenderClear(renderer);	

		while (SDL_PollEvent(&event)) {
			switch (event.type) {
				/* Look for a keypress */
				case SDL_KEYDOWN:
					/* Check the SDLKey values and move change the coords */
					switch (event.key.keysym.sym) {
						case SDL_SCANCODE_ESCAPE:
							running = false;
							break;
						case SDLK_a:
							pos_x -= 4;
							break;
						case SDLK_d:
							pos_x += 4;
							break;
						case SDLK_w:
							pos_y -= 4;
							break;
						case SDLK_s:
							pos_y += 4;
							break;
						case SDLK_LEFT:
							pos_r += 0.1;
							break;
						case SDLK_RIGHT:
							pos_r -= 0.1;
							break;
						case SDLK_SPACE:
							pos_h++;
							break;
						case SDLK_q:
							pos_h--;
							break;
						default:
							break;
					}
					break;
				case SDL_QUIT:
					running = false;
					break;
			}
		}

		render(pos_x, pos_y, pos_r , pos_h, 240, 120, 500, WIN_X, WIN_Y);

		SDL_UpdateTexture(
			texture,
			NULL,
			screen_data,
			WIN_X * 4
		);

		SDL_RenderCopy(renderer, texture, NULL, NULL);
		SDL_RenderPresent(renderer);

		frames++;
		const Uint64 end = SDL_GetPerformanceCounter();
		const static Uint64 freq = SDL_GetPerformanceFrequency();
		const double seconds = (end - start) / static_cast<double>(freq);
		if (seconds > 2.0) {
			std::cout
				<< frames << " frames in "
				<< std::setprecision(1) << std::fixed << seconds << " seconds = "
				<< std::setprecision(1) << std::fixed << frames / seconds << " FPS ("
				<< std::setprecision(3) << std::fixed << (seconds * 1000.0) / frames << " ms/frame)"
				<< std::endl;
			start = end;
			frames = 0;
		}

		const Uint64 anim_end = SDL_GetPerformanceCounter();
		const double anim = (anim_end - anim_start) / static_cast<double>(freq);
		if (anim > 0.25) {
			// anim_text = (anim_text+1)%4;
			anim_start = anim_end;
		}
	}

	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();

	return 0;
}