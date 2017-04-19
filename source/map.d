import std.math;
import std.typecons;
import geom;

struct Tilemap(T) 
{
	private Nullable!T[] buffer;
	private int width, height, tileWidth, tileHeight;

	this(int width, int height, int tileWidth, int tileHeight) 
	{
		this.width = width;
		this.height = height;
		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;
		buffer.length = (width / tileWidth) * (height / tileHeight);
	}

	private size_t index(const int x, const int y) const
	{
		const int tx = x / tileWidth;
		const int ty = y / tileHeight;
		return tx * tileHeight + ty;
	}

	public void set(const int x, const int y, T val) 
	{
		buffer[index(x, y)] = val;
	}

	public void set(E)(const E point, T val)
	{
		set(point.x, point.y, val);
	}

	public void clear(const int x, const int y) 
	{
		buffer[index(x, y)].nullify();
	}

	public void clear(E)(const E point)
	{
		clear(point.x, point.y);
	}

	public Nullable!T get(const int x, const int y) const
	{
		return buffer[index(x, y)];
	}

	public Nullable!T get(E)(const E point) const 
	{
		return get(point.x, point.y);
	}

	public bool isFree(int x, int y, int w, int h) const
	{
		const int lowX = x / tileWidth;
		const int lowY = y / tileHeight;
		const int highX = (x + w) / tileWidth;
		const int highY = (y + h) / tileHeight;
		for (int i = lowX; i <= highX; i++)
			for (int j = lowY; j <= highY; j++)
				if(!buffer[index(i * tileWidth, j * tileHeight)].isNull()) 
					return false;
		return true;
	}

	public bool isFree(E)(const E area) const 
	{
		return isFree(area.x, area.y, area.width, area.height);
	}

	public Vector2 linearMove(const Rectangle area, const Vector2 velocity) const
	{
		if(isFree(area.x + velocity.x, area.y + velocity.y, area.width, area.height))
		{
			return velocity;
		}
		else
		{
			int x = velocity.x;
			int y = velocity.y;
			while((x != 0 || y != 0) && !isFree(area.x + x, area.y + y, area.width, area.height))
			{
				x -= sgn(x);
				y -= sgn(y);
			}
			return Vector2(x, y);
		}
	}


	public Vector2 slideMove(const Rectangle area, const Vector2 velocity) const
	{
		if(isFree(area.x + velocity.x, area.y + velocity.y, area.width, area.height))
		{
			return velocity;
		}
		else
		{
			auto xcomp = linearMove(area, Vector2(velocity.x, 0));
			auto ycomp = linearMove(area, Vector2(0, velocity.y));
			Vector2 shrunk = Vector2(xcomp.x, ycomp.y);
			return linearMove(area, shrunk);
		}
	}
}
