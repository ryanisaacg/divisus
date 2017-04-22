import std.algorithm;
import std.container.array;
import std.math;
import std.parallelism;
import std.stdio;
import entity;
import geom;
import graphics;
import input;
import tilemap;
	
alias Map = Tilemap!(int, 640, 480, 32);


class Game
{
	Map map;
	Player player;
	Array!Enemy enemies;
	Array!Shield shields;

	Texture playerTex, enemyTex, shieldTex;

	Rect camera;

	this(Renderer draw)
	{
		map = new Map;
		player = Player(Rect(100, 100, 32, 32), Vector2(0, 0), Vector2(0, 1), Vector2(0.25, 0), Vector2(4, 20));
		player.a = PlayerAbility.Strike;
		player.b = PlayerAbility.Block;
		playerTex = draw.loadTexture("player.png");
		enemyTex = playerTex;
		shieldTex = playerTex;
		enemies.insertBack(Enemy(Rect(200, 200, 32, 32), Vector2(5, 0), Vector2(0, 1), Vector2(0, 0), Vector2(5, 5), EnemyType.Patrol, 1));
		camera = Rect(0, 0, 640, 480);
	}

	@nogc void update(Keyboard keys, Keyboard prevKeys, Mouse mouse, Mouse prevMouse)
	{
		updatePlayer(keys, prevKeys);
		moveEntity(player);
		foreach(ref enemy; enemies)
		{
			updateEnemy(enemy);
			moveEntity(enemy);
		}
		foreach(ref shield; shields)
		{
			shield.bounds.x += shield.velocity.x;
			shield.bounds.y += shield.velocity.y;
		}
	}

	@nogc void render(ref Window win)
	{
		win.draw.clear();
		renderTex(win, playerTex, player.bounds, player.iframes != 0 ? 128 : 255);
		foreach(ref enemy; enemies)
			renderTex(win, enemyTex, enemy.bounds, 255);
		foreach(ref shield; shields)
			renderTex(win, shieldTex, shield.bounds, 128);
		win.draw.display();
	}

	@nogc void moveEntity(Entity)(ref Entity entity)
	{
		entity.velocity = (entity.velocity + entity.acceleration).limit(entity.maxVelocity).drag(entity.drag);
		map.slide(entity.bounds, entity.velocity, entity.bounds, entity.velocity);
	}
	
	@nogc void updatePlayer(Keyboard keys, Keyboard prevKeys) 
	{
		player.acceleration.x = 0;
		if(keys.isPressed!"D")
		{
			player.faceLeft = false;
			player.acceleration.x += 0.5;
		} 
		if(keys.isPressed!"A")
		{
			player.faceLeft = true;
			player.acceleration.x -= 0.5;
		}
		if(keys.isPressed!"W" && !prevKeys.isPressed!"W" && map.supported(player.bounds))
		{
			player.velocity.y = -12;
			player.holdingJump = true;
		}
		if(keys.isPressed!"J")
			doAbility(player.b);
		if(keys.isPressed!"K")
			doAbility(player.a);
		if(player.abilityCooldown <= 0)
			player.currentAction = PlayerAbility.None;
		else
			player.abilityCooldown--;

		player.holdingJump = player.holdingJump && keys.isPressed!"W";
		player.acceleration.y = player.holdingJump ? 0.5 : 1.2;
		if(sgn(player.velocity.x) != sgn(player.acceleration.x))
		{
			player.acceleration.x *= 2;
		}
		if(player.iframes > 0)
			player.iframes--;
	}

	@nogc void doAbility(PlayerAbility ability)
	{
		if(player.abilityCooldown > 0) return;
		switch(ability) {
		case PlayerAbility.Block:
			shields.insertBack(Shield(Rect(player.bounds.x + player.bounds.width / 2 - 2, 
					player.bounds.y, 4, player.bounds.height), 
					Vector2(10 * (player.faceLeft ? -1 : 1), 0)));
			player.abilityCooldown = 15;
			break;
		case PlayerAbility.Reflect:
			player.abilityCooldown = 60;
			break;
		case PlayerAbility.Strike:
			Rect hitbox = Rect(player.bounds.x + player.bounds.width / 2, 
					player.bounds.y + player.bounds.height / 2 - 3, 96, 6);
			if(player.faceLeft)
				hitbox.x -= 96;
			foreach(ref enemy; enemies) 
			{
				if(enemy.bounds.overlaps(hitbox)) 
				{
					enemy.health--;
				}
			}
			player.abilityCooldown = 60;
			break;
		case PlayerAbility.Dash:
			//TODO: implement
			break;
		case PlayerAbility.Shoot:
			//TODO: implement
			break;
		default:
			break;
		}
		player.currentAction = ability;
	}

	@nogc void updateEnemy(ref Enemy enemy)
	{
		switch(enemy.type)
		{
		case EnemyType.Patrol:
			//Patrol back and forth, switching at walls and not walking off platforms
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
		//Hit-based enemies
		if(enemy.type == EnemyType.Patrol && player.iframes == 0 && player.bounds.overlaps(enemy.bounds))
		{
			player.power --;
			player.iframes = 60;
		}
	}

	@nogc void renderTex(ref Window win, Texture texture, Rect bounds, ubyte alpha)
	{
		bounds.x -= camera.x;
		bounds.y -= camera.y;
		float x = win.width / camera.width;
		float y = win.height / camera.height;
		bounds.x *= win.width / camera.width;
		bounds.y *= win.height / camera.height;
		bounds.width *= win.width / camera.width;
		bounds.height *= win.height / camera.height;
		win.draw.draw(texture, cast(int)bounds.x, cast(int)bounds.y, cast(int)bounds.width, cast(int)bounds.height, 0, false, false, alpha);
	}

	void clearDead()
	{
		for(int i = 0; i < shields.length; i++)
		{
			if(!map.is_empty(shields[i].bounds))
			{
				shields[i] = shields[$ - 1];
				shields.removeBack();
				i--;
			}
		}
		for(int i = 0; i < enemies.length; i++)
		{
			if(enemies[i].health < 0)
			{
				enemies[i] = enemies[$ - 1];
				enemies.removeBack();
				i--;
			}
		}
	}
}


