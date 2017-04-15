module tile;

import derelict.sdl2.sdl;

import box;

struct Tile 
{
	SDL_Texture* texture;
	box2i texRegion, gameRegion;
}
