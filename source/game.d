import entity;
import geom;
import graphics;
import tilemap;

class Game
{
	alias Map = Tilemap!(int, 6400, 4800, 32);

	Map map;
	Entity[] entities;

	Entity *player;

	Texture playerTex;

	this(Renderer draw)
	{
		map = new Map;
	}

	void update()
	{

	}

	void tick(Renderer draw)
	{

	}

}
