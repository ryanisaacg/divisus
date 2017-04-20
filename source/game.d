import std.parallelism;
import entity;
import geom;
import graphics;
import tilemap;

class Game
{
	alias Map = Tilemap!(int, 640, 480, 32);

	Map map;
	Entity[] entities;

	Texture playerTex;

	this(Renderer draw)
	{
		map = new Map;
		entities.length = 1;
		entities[0] = Entity(Rect(100, 100, 32, 32), Vector2(0, 0), Vector2(0, 0.01), EntityType.Player);
		playerTex = draw.loadTexture("player.bmp");
	}

	void update()
	{
		foreach(i, ref entity; taskPool.parallel(entities))
		{
			entity.speed = entity.speed + entity.acceleration;
			map.slide(entity.bounds, entity.speed, entity.bounds, entity.speed);
		}
	}

	void render(Renderer draw)
	{
		draw.clear();
		foreach(i, ref entity; entities)
		{
			Texture tex;
			switch(entity.type)
			{
			case EntityType.Player:
				tex = playerTex;
				break;
			default:
				break;
			}
			draw.draw(tex, cast(int)entity.bounds.x, cast(int)entity.bounds.y, cast(int)entity.bounds.width, cast(int)entity.bounds.height);
		}
		draw.display();
	}

}
