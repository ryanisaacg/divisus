import geom;

struct Player
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	bool holdingJump;
}

enum EnemyType { Patrol }

struct Enemy
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	EnemyType type;
}
