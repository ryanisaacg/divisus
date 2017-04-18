import std.stdio;
import map;

void main()
{
	Tilemap!int map = Tilemap!int(640, 480, 32, 32);
	map.set(5, 5, 1);
	writeln(map.get(6, 33));
}
