import entity;
import geom;
import graphics;
import input;
import std.parallelism;
import std.stdio;
import std.typecons;
import tilemap;
import update;
import util;

void main()
{
	auto window = Window("Project Divisus", 640, 480);
	auto draw = window.createRenderer(); 
	Game game = new Game(draw);
	while(true)
	{
		Nullable!Event event;
		while(!(event = pollEvent).isNull())
			window.processEvent(event);
	}

}
