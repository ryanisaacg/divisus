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
	Array!Projectile shields, enemyBullets, playerBullets;

	Texture playerTex, enemyTex, shieldTex, playerBulletTex, enemyBulletTex;

	Rect camera;

	this(Renderer draw)
	{
		map = new Map;
		player = Player(Rect(100, 100, 32, 32), Vector2(0, 0), Vector2(0, 1), Vector2(0.25, 0), Vector2(4, 20));
		player.a = PlayerAbility.Dash;
		player.b = PlayerAbility.Shoot;
		playerTex = draw.loadTexture("player.png");
		enemyTex = playerTex;
		shieldTex = playerTex;
		playerBulletTex = playerTex;
		enemyBulletTex = playerTex;
		enemies.insertBack(Enemy(Rect(200, 200, 32, 32), Vector2(5, 0), Vector2(0, 1), Vector2(0, 0), Vector2(5, 5), EnemyType.Turret, 1));
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
			foreach(ref enemyBullet; enemyBullets)
			{
				if(shield.bounds.overlaps(enemyBullet.bounds))
				{
					shield.health--;
					enemyBullet.health--;
				}
			}
		}
		foreach(ref playerBullet; playerBullets)
		{
			playerBullet.bounds.x += playerBullet.velocity.x;
			playerBullet.bounds.y += playerBullet.velocity.y;
			foreach(ref enemy; enemies)
			{
				if(playerBullet.bounds.overlaps(enemy.bounds))
				{
					playerBullet.health--;
					enemy.health--;
				}
			}
		}
		foreach(ref enemyBullet; enemyBullets)
		{
			enemyBullet.bounds.x += enemyBullet.velocity.x;
			enemyBullet.bounds.y += enemyBullet.velocity.y;
			if(player.iframes <= 0 && player.bounds.overlaps(enemyBullet.bounds))
			{
				if(player.currentAction != PlayerAbility.Dash)
					player.power--;
				enemyBullet.health--;
			}
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
		foreach(ref bullet; playerBullets)
			renderTex(win, playerBulletTex, bullet.bounds, 255);
		foreach(ref bullet; enemyBullets)
			renderTex(win, enemyBulletTex, bullet.bounds, 255);
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
		{
			player.currentAction = PlayerAbility.None;
			player.maxVelocity.x = 4;
			player.drag.x = 0.25;
		}
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
			shields.insertBack(Projectile(Rect(player.bounds.x + player.bounds.width / 2 - 2, 
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
			player.velocity.x = 30 * (player.faceLeft ? -1 : 1);
			player.maxVelocity.x = 30;
			player.drag.x = 0;
			player.abilityCooldown = 5;
			break;
		case PlayerAbility.Shoot:
			playerBullets.insertBack(Projectile(Rect(player.bounds.x + player.bounds.width / 2 - 2,
					player.bounds.y + player.bounds.height / 2 - 2, 4, 4),
					Vector2(15 * (player.faceLeft ? -1 : 1), 0)));
			player.abilityCooldown = 15;
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
		case EnemyType.Turret:
			if(enemy.cooldown <= 0)
			{
				enemyBullets.insertBack(Projectile(Rect(enemy.bounds.x + player.bounds.width / 2 -2,
						player.bounds.y + player.bounds.height / 2 -2, 4, 4),
						(Vector2(player.bounds.x + player.bounds.width / 2, player.bounds.y + player.bounds.height / 2) 
						 - Vector2(enemy.bounds.x + enemy.bounds.width / 2, enemy.bounds.y + enemy.bounds.height / 2))
						.setLength(15)));
				enemy.cooldown = 120;
			}
			else
			{
				enemy.cooldown -= 1;
			}
			break;
		default:
			break;
		}
		//Hit-based enemies
		if(enemy.type == EnemyType.Patrol && player.iframes == 0 && player.bounds.overlaps(enemy.bounds))
		{
			if(player.currentAction == PlayerAbility.Dash)
			{
				enemy.health--;
			}
			else
			{
				player.power --;
				player.iframes = 60;
			}
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


	void clearProjectiles(Array!Projectile projectiles)
	{
		for(int i = 0; i < projectiles.length; i++)
		{
			if(projectiles[i].health < 0 || !map.is_empty(projectiles[i].bounds))
			{
				projectiles[i] = projectiles[$ - 1];
				projectiles.removeBack();
				i--;
			}
		}
	}

	void clearByHealth(T)(Array!T entities)
	{
		for(int i = 0; i < entities.length; i++)
		{
			if(entities[i].health <= 0)
			{
				entities[i] = entities[$ - 1];
				entities.removeBack();
				i--;
			}
		}

	}

	void clearDead()
	{
		clearProjectiles(shields);
		clearProjectiles(playerBullets);
		clearProjectiles(enemyBullets);
		clearByHealth(enemies);
	}
}


