import std.math;
import std.typecons;
import geom;

/**
 * A tiled map of items
 * T- the item type
 * Width, Height, and TileSize define the grid bounds
 */
class Tilemap(T, int Width, int Height, int TileSize) {
	//The grid data
	Nullable!T[Height / TileSize][Width / TileSize] data;
	
	//Converts a Vector2 to data grid coordinates
	pure private void convert(Vector2 vec, out int x, out int y) {
		x = cast(int)(vec.x / TileSize);
		y = cast(int)(vec.y / TileSize);
	}
	
	pure private bool valid(int x, int y) {
		return x >= 0 && y >= 0 && x < Width / TileSize && y < Height / TileSize;
	} 
	
	//Do an action at a point
	template do_point(alias func) {
		private auto do_point(Vector2 point) {
			int x, y;
			convert(point, x, y);
			return func(x, y);
		}
	}
	
	//Do a paramterized action at a point
	template do_point(alias func, Type) {
		private auto do_point(Vector2 point, Type item) {
			int x, y;
			convert(point, x, y);
			return func(x, y, item);
		}
	}
	
	//Do an action over a region
	template do_region(alias func) {
		auto do_region(Rect region) {
			//If the region is smaller than a grid square, make sure it still gets checked at all corners
			for(float x = region.x; x <= region.x + region.width; x += TileSize) {
				for(float y = region.y; y <= region.y + region.height; y += TileSize) {
					Vector2 point = Vector2(x, y);
					//Don't check against points outside of the region
					if(region.contains(point)) {
						do_point!func(point);
					}
				}
			}
			do_point!func(Vector2(region.x + region.width, region.y));
			do_point!func(Vector2(region.x, region.y + region.height));
			do_point!func(Vector2(region.x + region.width, region.y + region.height));
		}
	}
	
	//Do a parameterized action over a region
	template do_region(alias func, Type) {
		auto do_region(Rect region, Type item) {
			//If the region is smaller than a grid square, make sure it still gets checked at all corners
			for(float x = region.x; x <= region.x + region.width; x += TileSize) {
				for(float y = region.y; y <= region.y + region.height; y += TileSize) {
					Vector2 point = Vector2(x, y);
					//Don't check against points outside of the region
					if(region.contains(point)) {
						do_point!func(point, item);
					}
				}
			}
			do_point!func(Vector2(region.x + region.width, region.y), item);
			do_point!func(Vector2(region.x, region.y + region.height), item);
			do_point!func(Vector2(region.x + region.width, region.y + region.height), item);
		}
	}
	
	private void put_array(int x, int y, T element) { data[x][y] = element; }
	///Put an item into the grid at a point
	void put(T item, Vector2 point) { do_point!put_array(point, item); }
	///Put an item into the grid over an area
	void put(T item, Rect area) { do_region!put_array(area, item); }
	
	private void remove_array(int x, int y) { data[x][y].nullify(); }
	///Remove an item from a point
	void remove(Vector2 point) { do_point!remove_array(point); }
	///Remove an item from a region
	void remove(Rect area) { do_region!remove_array(area); }
	
	pure private void is_empty_array(int x, int y, bool *empty) { 
		if(valid(x, y)) 
			*empty &= data[x][y].isNull(); 
		else
			*empty = false;
	}
	///Check if a point is empty
	pure bool is_empty(Vector2 point) { bool empty = true; do_point!is_empty_array(point, &empty); return empty; }
	///Check if a region is empty
	pure bool is_empty(Rect area) { bool empty = true; do_region!is_empty_array(area, &empty); return empty; }
	
	///Get the elements at a point
	pure private Nullable!T get_array(int x, int y) { 
		if(valid(x, y)) 
			return data[x][y]; 
		else {
			Nullable!T empty;
			return empty;
		}
	}
	pure Nullable!T get(Vector2 point) { return do_point!get_array(point); }

	pure bool supported(Rect rect) {
		rect.y += 1;
		return !is_empty(rect);
	}
	
	/** Move a rectangle at a speed
	 * If there is a non-empty spot in the way, stop the movement and return that stopped position and displacement
	 * Precondition: area is a free rectangle
	 * Postcondition: end_area is a free rectangle
	 */
	 void move(Rect area, Vector2 speed, out Rect end_area, out Vector2 end_speed) {
		 //If the rect isn't free, reflect the inputs but nullify speed
		if(!is_empty(area)) {
			end_area = area;
			end_speed = Vector2(0, 0);
		}
		//Move the rectangle, decreasing the displacement each attempt
		Vector2 change = -Vector2(sgn(speed.x), sgn(speed.y));
		while(speed.len > 0) {
			Rect attempt = area.move(speed);
			if(is_empty(attempt)) {
				end_area = attempt;
				end_speed = speed;
				return;
			} else if(speed.len < 1) {
				end_area = area;
				end_speed = speed;
				return;
			}
			speed = speed + change;
		}
		end_area = area;
		end_speed = Vector2(0, 0);
	}
	/**Slide a rectangle
	 * Attempt to move with x-speed, then y-speed, to allow for cases where there would be friction in real physics
	 */
	void slide(Rect area, Vector2 speed, out Rect end_area, out Vector2 end_speed) {
		Vector2 xspeed = Vector2(speed.x, 0);
		Vector2 yspeed = Vector2(0, speed.y);
		move(area, xspeed, end_area, xspeed);
		move(end_area, yspeed, end_area, yspeed);
		end_speed.x = xspeed.x;
		end_speed.y = yspeed.y;
	}
	int width() {
		return Width;
	}

	int height() {
		return Height;
	}
}
