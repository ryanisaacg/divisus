import std.math;
import std.parallelism;
import std.stdio;
import entity;
import geom;
import graphics;
import input;
import tilemap;
	
alias Map = Tilemap!(int, 640, 480, 32);

void updatePlayer(ref Player player, Keyboard keys, Keyboard prevKeys, Map map) 
{
	player.acceleration.x = 0;
	if(keys.isPressed!"D")
	{
		player.acceleration.x += 0.5;
	} 
	if(keys.isPressed!"A")
	{
		player.acceleration.x -= 0.5;
	}
	if(keys.isPressed!"W" && !prevKeys.isPressed!"W" && map.supported(player.bounds))
	{
		player.velocity.y = -12;
		player.holdingJump = true;
	}
	player.holdingJump = player.holdingJump && keys.isPressed!"W";
	player.acceleration.y = player.holdingJump ? 0.5 : 1;
	if(sgn(player.velocity.x) != sgn(player.acceleration.x))
	{
		player.acceleration.x *= 2;
	}
}

void updateEntity(Entity)(ref Entity entity, Map map)
{
	entity.velocity = (entity.velocity + entity.acceleration).limit(entity.maxVelocity).drag(entity.drag);
	map.slide(entity.bounds, entity.velocity, entity.bounds, entity.velocity);
}

void renderTex(Renderer draw, Texture texture, Rect bounds)
{
	draw.draw(texture, cast(int)bounds.x, cast(int)bounds.y, cast(int)bounds.width, cast(int)bounds.height);
}

class Game
{
	Map map;
	Player player;

	Texture playerTex;

	this(Renderer draw)
	{
		map = new Map;
		player = Player(Rect(100, 100, 32, 32), Vector2(0, 0), Vector2(0, 1), Vector2(0.25, 0), Vector2(4, 20));
		playerTex = draw.loadTexture("player.png");
	}

	void update(Keyboard keys, Keyboard prevKeys, Mouse mouse, Mouse prevMouse)
	{
		updatePlayer(player, keys, prevKeys, map);
		updateEntity(player, map);
	}

	void render(Renderer draw)
	{
		draw.clear();
		renderTex(draw, playerTex, player.bounds);
		draw.display();
	}

}
