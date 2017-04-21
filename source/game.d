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

void updateEnemy(ref Enemy enemy, Map map)
{
	switch(enemy.type)
	{
	case EnemyType.Patrol:
		Rect bounds = enemy.bounds;
		bounds.x += enemy.velocity.x;
		if(!map.is_empty(bounds))
			enemy.velocity.x *= -1;
		bounds.x += sgn(enemy.velocity.x) * bounds.width;
		if(!map.supported(bounds))
			enemy.velocity.x *= -1;
		break;
	default:
		break;
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
	Enemy[] enemies;

	Texture playerTex, enemyTex;

	this(Renderer draw)
	{
		map = new Map;
		player = Player(Rect(100, 100, 32, 32), Vector2(0, 0), Vector2(0, 1), Vector2(0.25, 0), Vector2(4, 20));
		playerTex = draw.loadTexture("player.png");
		enemyTex = playerTex;
		enemies.length = 1;
		enemies[0] = Enemy(Rect(200, 200, 32, 32), Vector2(5, 0), Vector2(0, 1), Vector2(0, 0), Vector2(5, 5));
	}

	void update(Keyboard keys, Keyboard prevKeys, Mouse mouse, Mouse prevMouse)
	{
		updatePlayer(player, keys, prevKeys, map);
		updateEntity(player, map);
		foreach(ref enemy; enemies)
		{
			updateEnemy(enemy, map);
			updateEntity(enemy, map);
		}
	}

	void render(Renderer draw)
	{
		draw.clear();
		renderTex(draw, playerTex, player.bounds);
		foreach(ref enemy; enemies)
			renderTex(draw, enemyTex, enemy.bounds);
		draw.display();
	}

}
