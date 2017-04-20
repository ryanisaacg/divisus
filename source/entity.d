import geom;

enum EntityType { Player }

struct Entity {
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	EntityType type;
}
