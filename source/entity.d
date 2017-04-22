import geom;

struct Player
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	bool holdingJump, faceLeft;
	int power, iframes, abilityCooldown;
	PlayerAbility a, b;
}

enum PlayerAbility { Block, Reflect, Strike, Dash, Shoot }

enum EnemyType { Patrol }

struct Enemy
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	EnemyType type;
}
