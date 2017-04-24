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
		player.a = PlayerAbility.Block;
		player.b = PlayerAbility.Reflect;
		player.power = player.maxPower = 50;
		playerTex = draw.loadTexture("player.png");
		enemyTex = playerTex;
		shieldTex = playerTex;
		playerBulletTex = playerTex;
		enemyBulletTex = playerTex;
		enemies.insertBack(Enemy(Rect(200, 200, 32, 32), Vector2(5, 0), Vector2(0, 1), Vector2(0, 0), Vector2(35, 35), EnemyType.Turret, 1));
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
			shield.x = shield.x + shield.velocity.x;
			shield.y = shield.y + shield.velocity.y;
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
			playerBullet.x = playerBullet.x + playerBullet.velocity.x;
			playerBullet.y = playerBullet.y + playerBullet.velocity.y;
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
			enemyBullet.x = enemyBullet.x + enemyBullet.velocity.x;
			enemyBullet.y = enemyBullet.y + enemyBullet.velocity.y;
			if(player.iframes <= 0 && player.bounds.overlaps(enemyBullet.bounds))
			{
				if(player.currentAction != PlayerAbility.Reflect && player.currentAction != PlayerAbility.Dash)
					player.power--;
				enemyBullet.health--;
				if(player.currentAction == PlayerAbility.Reflect)
					playerBullets.insertBack(Projectile(enemyBullet.bounds, -enemyBullet.velocity));
			}
		}
	}

	@nogc void render(ref Window win)
	{
		win.draw.setColor(Color(0, 0, 0, 255));
		win.draw.clear();
		renderEntities(win);
		renderUI(win);
		win.draw.display();
	}

	@nogc void renderEntities(ref Window win)
	{
		renderTex(win, playerTex, player.bounds, player.iframes != 0 ? 128 : 255);
		foreach(ref enemy; enemies)
			renderTex(win, enemyTex, enemy.bounds, 255);
		foreach(ref shield; shields)
			renderTex(win, shieldTex, shield.bounds, 128);
		foreach(ref bullet; playerBullets)
			renderTex(win, playerBulletTex, bullet.bounds, 255);
		foreach(ref bullet; enemyBullets)
			renderTex(win, enemyBulletTex, bullet.bounds, 255);
	}

	@nogc void renderUI(ref Window win)
	{
		win.draw.setColor(Color(128, 128, 128, 255));
		win.draw.fillRect(15, 15, win.width - 15, 30);
		win.draw.setColor(Color(0, 128, 128, 255));
		win.draw.fillRect(20, 20, cast(int)((win.width - 20) * (player.power / cast(float)player.maxPower)), 20);
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
			shields.insertBack(Projectile(Rect(player.centerX - 8, player.y, 16, player.height), 
					Vector2(10 * (player.faceLeft ? -1 : 1), 0)));
			player.abilityCooldown = 15;
			break;
		case PlayerAbility.Reflect:
			player.abilityCooldown = 120;
			break;
		case PlayerAbility.Strike:
			Rect hitbox = Rect(player.centerX, player.centerY - 3, 96, 6);
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
			playerBullets.insertBack(Projectile(Rect(player.centerX - 2, player.centerY - 2, 4, 4),
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
				enemyBullets.insertBack(Projectile(Rect(enemy.centerX - 2, enemy.centerY - 2, 4, 4),
						(player.center - enemy.center).setLength(15)));
				enemy.cooldown = 60;
			}
			else
			{
				enemy.cooldown -= 1;
			}
			break;
		case EnemyType.HunterKiller:
			if((enemy.center - player.center).len() <= 360)
			{
				if(player.x + 10 < enemy.x)
					enemy.velocity.x = -3;
				else if(player.x - 10 > enemy.x)
					enemy.velocity.x = 3;
				if(player.y + player.height * 2 < enemy.y && enemy.x < player.x + player.width 
						&& enemy.x + enemy.width > player.x && map.supported(enemy.bounds))
					enemy.velocity.y = -15;
				if(enemy.cooldown <= 0)
				{
					for(int i = -1; i <= 1; i++)
						for(int j = -1; j <= 1; j++)
							if(i != 0 || j != 0)
								enemyBullets.insertBack(Projectile(Rect(enemy.centerX - 2, enemy.centerY - 2, 4, 4),
									Vector2(i * 6, j * 6)));
					enemy.cooldown = 120;
				}
				else
				{
					enemy.cooldown--;
				}
			}
			break;
		case EnemyType.Leaper:
			if(enemy.velocity.y == 0)
			{
				if((enemy.center - player.center).len() <= 360)
				{
					enemy.velocity.y = -30;
				}
				else
				{
					if(player.x + 10 < enemy.x)
						enemy.velocity.x = -3;
					if(player.x - 10 > enemy.x)
						enemy.velocity.x = 3;
				}
			} 
			else if(enemy.velocity.y < 0)
			{
				if(player.x + 10 < enemy.x)
					enemy.velocity.x = -1;
				if(player.x - 10 > enemy.x)
					enemy.velocity.x = 1;
			}
			else
			{
				if(player.x + 10 < enemy.x)
					enemy.velocity.x = -5;
				if(player.x - 10 > enemy.x)
					enemy.velocity.x = 5;
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


