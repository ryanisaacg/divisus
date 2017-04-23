import geom;

struct Player
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	bool holdingJump, faceLeft;
	int power, iframes, abilityCooldown;
	PlayerAbility a, b;
	PlayerAbility currentAction;
}

enum PlayerAbility { Block, Reflect, Strike, Dash, Shoot, None }

enum EnemyType { Patrol, Turret }

struct Enemy
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	EnemyType type;
	int health, cooldown;
}

struct Projectile
{
	Rect bounds;
	Vector2 velocity;
	int health;
}
