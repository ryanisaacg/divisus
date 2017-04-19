import std.stdio;
import map;
import geom;

void main()
{
	Tilemap!int map = Tilemap!int(640, 480, 32, 32);
	map.set(5, 5, 1);
	auto player = Rectangle(30, 38, 4, 4);
	auto vec = Vector2(-1, -10);
	writeln(map.slideMove(player, vec));
}
