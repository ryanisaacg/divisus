import std.math;
import std.parallelism;
import entity;
import geom;
import graphics;
import input;
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
		entities[0] = Entity(Rect(100, 100, 32, 32), Vector2(0, 0), Vector2(0, 0.1), Vector2(0.25, 0), Vector2(4, 20), EntityType.Player);
		playerTex = draw.loadTexture("player.png");
	}

	void update(Keyboard keys, Keyboard prevKeys, Mouse mouse, Mouse prevMouse)
	{
		foreach(i, ref entity; taskPool.parallel(entities))
		{
			if(entity.type == EntityType.Player) 
			{
				entity.acceleration.x = 0;
				if(keys.isPressed!"D")
				{
					entity.acceleration.x = 0.5;
				} 
				else if(keys.isPressed!"A")
				{
					entity.acceleration.x = -0.5;
				}
				if(sgn(entity.velocity.x) != sgn(entity.acceleration.x))
				{
					entity.acceleration.x *= 2;
				}
			}
			entity.velocity = (entity.velocity + entity.acceleration).limit(entity.maxVelocity).drag(entity.drag);
			map.slide(entity.bounds, entity.velocity, entity.bounds, entity.velocity);
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
