import std.stdio;
import std.typecons;
import entity;
import geom;
import graphics;
import input;
import tilemap;
import game;
import util;

void main()
{
	auto window = Window("Project Divisus", 640, 480);
	Game game = new Game(window.draw);
	while(!window.closed)
	{
		window.resetInput();
		Nullable!Event event;
		while(!(event = pollEvent).isNull())
			window.processEvent(event);
		game.update(window.keyboard, window.previousKeyboard, window.mouse, window.previousMouse);
		game.clearDead();
		game.render(window);
		sleep(16);
	}

}
