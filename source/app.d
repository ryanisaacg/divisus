import std.stdio;
import tilemap;
import entity;
import geom;

alias Map = Tilemap!(int, 640, 480, 32);

void main()
{
	Map map = new Map;
	for(int i = 0; i < 480; i++)
		map.put(1, Vector2(i, i));
	Entity[] entities;
	entities.length = 15;
	for(int i = 0; i < entities.length; i++)
	{
		entities[i] = Entity(Rect(450, i * 32, 32, 32), Vector2(-1, 0));
	}
	for(int i = 0; i < 1000; i++) 
	{
		foreach(index, ref ent; entities) 
		{
			map.slide(ent.bounds, ent.speed, ent.bounds, ent.speed);
		}
	}
	foreach(i, ref ent; entities) 
	{
		writeln(ent);
	}
}
