import geom;

struct Player
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	bool holdingJump;
	int power;
	int iframes;
}

enum EnemyType { Patrol }

struct Enemy
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	EnemyType type;
}
