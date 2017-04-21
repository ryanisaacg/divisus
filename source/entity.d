import geom;

struct Player
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	bool holdingJump;
}
