import geom;

enum EntityType { Player }

struct Entity {
	Rect bounds;
	Vector2 speed;
	Vector2 acceleration;
	EntityType type;
}
