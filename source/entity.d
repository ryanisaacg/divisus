import geom;
const char[] properties = `
	@property @nogc float x() { return bounds.x; }
	@property @nogc float x(float val) { return bounds.x = val; }
	@property @nogc float y() { return bounds.y; }
	@property @nogc float y(float val) { return bounds.y = val; }
	@property @nogc float width() { return bounds.width; }
	@property @nogc float width(float val) { return bounds.width = val; }
	@property @nogc float height() { return bounds.height; }
	@property @nogc float height(float val) { return bounds.height = val; }
	@property @nogc float centerX() { return x + width / 2; }
	@property @nogc float centerX(float val) { return x = val - width / 2; }
	@property @nogc float centerY() { return y + height / 2; }
	@property @nogc float centerY(float val) { return y = val - height / 2; }
	@property @nogc Vector2 center() { return Vector2(centerX, centerY); }
	`;

struct Player
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	bool holdingJump, faceLeft;
	int power, iframes, abilityCooldown, maxPower;
	PlayerAbility a, b;
	PlayerAbility currentAction;
	mixin(properties);
}

enum PlayerAbility { Block, Reflect, Strike, Dash, Shoot, None }

enum EnemyType { Patrol, Turret, HunterKiller, Leaper }

struct Enemy
{
	Rect bounds;
	Vector2 velocity, acceleration, drag, maxVelocity;
	EnemyType type;
	int health, cooldown;
	mixin(properties);
}

struct Projectile
{
	Rect bounds;
	Vector2 velocity;
	int health;
	mixin(properties);
}
