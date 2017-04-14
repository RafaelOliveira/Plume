package plume.collision;

import kha.math.Vector2;
import plume.math.Rectangle;

class Body
{
	public inline static var HITBOX:Int = 0;
	public inline static var GRID:Int = 1;

	public var pos:Vector2;
	public var rect:Rectangle;
	public var collidable:Bool;
	public var type:Int = HITBOX;

	// Collision information	
	var _moveX:Float;
	var _moveY:Float;

	public function new(pos:Vector2, rect:Rectangle):Void
	{
		this.pos = pos;
		this.rect = rect;
		collidable = true;
	}

	/**
	 * Checks if this Body collides with a specific Body.
	 * @param	body	The Body to collide against.
	 * @param	x		Virtual x position to place this Body.
	 * @param	y		Virtual y position to place this Body.
	 * @return	The Body if they overlap, or null if they don't.
	 */
	public function collideBody(body:Body, x:Float, y:Float):Body
	{
		if (collidable && body.collidable)
		{
			if (rect.collisionProjected(x, y, body.rect, body.pos.x, body.pos.y))
			{
				if (type == Body.HITBOX && body.type == Body.HITBOX)
						return body;
				else (type == Body.HITBOX && body.type == Body.GRID)
				{
					var grid:Grid = cast body;
					return grid.collideBody(this, x, y);
				}
			}
		}

		return null;
	}

	/**
	 * Checks for a collision against an array.
	 * @param	list		The array to check for.
	 * @param	x			Virtual x position to place this Body.
	 * @param	y			Virtual y position to place this Body.
	 * @return	The first Body collided with, or null if none were collided.
	 */
	public function collideArray(list:Array<Body>, x:Float, y:Float):Body
	{
		if (!collidable)
			return null;

		for (e in list)
		{
			if (e.collidable && e != this && rect.collisionProjected(x, y, e.rect, e.pos.x, e.pos.y))
			{
				if (type == Body.HITBOX && e.type == Body.HITBOX)
					return e;
				else (type == Body.HITBOX && e.type == Body.GRID)
				{
					var grid:Grid = cast e;					
					return grid.collideBody(this, x, y);
				}
			}
		}

		return null;
	}

	/**
	 * Checks if this Body overlaps the specified rectangle.
	 * @param	x			Virtual x position to place this Object.
	 * @param	y			Virtual y position to place this Object.
	 * @param	rX			X position of the rectangle.
	 * @param	rY			Y position of the rectangle.
	 * @param	rWidth		Width of the rectangle.
	 * @param	rHeight		Height of the rectangle.
	 * @return	If they overlap.
	 */
	public function collideRect(x:Float, y:Float, rX:Float, rY:Float, rWidth:Float, rHeight:Float):Bool 
	{
		if (x + rect.x + rect.width > rX &&
			y + rect.y + rect.height > rY &&
			x + rect.x < rX + rWidth &&
			y + rect.y < rY + rHeight)
			return true;		
		else
			return false;
	}

	/**
	 * Checks if this Object overlaps the specified position.
	 * @param	x			Virtual x position to place this Body.
	 * @param	y			Virtual y position to place this Body.
	 * @param	pX			X position.
	 * @param	pY			Y position.
	 * @return	If the Object intersects with the position.
	 */
	public function collidePoint(x:Float, y:Float, px:Float, py:Float):Bool
	{
		if (px >= (x + rect.x) &&
			py >= (y + rect.y) &&
			px < (x + rect.x + rect.width) &&
			py < (y + rect.y + rect.height))
			return true;
		else
			return false;
	}

	/**
	 * Moves the Body by the amount, retaining integer values for its x and y.
	 * @param	x			Horizontal offset.
	 * @param	y			Vertical offset.
	 * @param	list		An optional array to stop flush against upon collision.
	 * @param	sweep		If sweeping should be used (prevents fast-moving bodies from going through the array).
	 */
	public function moveBy(x:Float, y:Float, ?list:Array<Body>, sweep:Bool = false):Void
	{
		_moveX += x;
		_moveY += y;
		x = Math.round(_moveX);
		y = Math.round(_moveY);
		_moveX -= x;
		_moveY -= y;

		if (list != null)
		{		
			var sign:Int, e:Body;

			if (x != 0)
			{
				if (collidable && (sweep || collideArray(list, pos.x + x, pos.y) != null))
				{
					sign = x > 0 ? 1 : -1;

					while (x != 0)
					{
						if ((e = collideArray(list, pos.x + sign, pos.y)) != null)
						{
							if (moveCollideX(e))
								break;
							else 
								pos.x += sign;
						}
						else
							pos.x += sign;

						x -= sign;
					}
				}
				else 
					pos.x += x;
			}
			if (y != 0)
			{
				if (collidable && (sweep || collideArray(list, pos.x, pos.y + y) != null))
				{
					sign = y > 0 ? 1 : -1;

					while (y != 0)
					{
						if ((e = collideArray(list, pos.x, pos.y + sign)) != null)
						{
							if (moveCollideY(e)) 
								break;
							else 
								pos.y += sign;
						}
						else
							pos.y += sign;

						y -= sign;
					}
				}
				else
					pos.y += y;
			}
		}
		else
		{
			pos.x += x;
			pos.y += y;
		}
	}

	/**
	 * Moves the Body to the position, retaining integer values for its x and y.
	 * @param	x			X position.
	 * @param	y			Y position.
	 * @param	list		An optional array to stop flush against upon collision.
	 * @param	sweep		If sweeping should be used (prevents fast-moving bodies from going through the array).
	 */
	public inline function moveTo(x:Float, y:Float, ?list:Array<Body>, sweep:Bool = false):Void
	{
		moveBy(x - pos.x, y - pos.y, list, sweep);
	}

	/**
	 * Moves towards the target position, retaining integer values for its x and y.
	 * @param	x			X target.
	 * @param	y			Y target.
	 * @param	amount		Amount to move.
	 * @param	list		An optional array to stop flush against upon collision.
	 * @param	sweep		If sweeping should be used (prevents fast-moving bodies from going through the array).
	 */
	public function moveTowards(x:Float, y:Float, amount:Float, ?list:Array<Body>, sweep:Bool = false):Void
	{
		var point = new Vector2(x - pos.x, y - pos.y);
		
		if (point.x * point.x + point.y * point.y > amount * amount)		
			normalizeThickness(point, amount);
		
		moveBy(point.x, point.y, list, sweep);
	}

	/**
	 * When you collide with an Body on the x-axis with moveTo() or moveBy()
	 * the engine call this function. Override it to detect and change the
	 * behaviour of collisions.
	 *
	 * @param	e	The Body you collided with.
	 *
	 * @return	If there was a collision.
	 */
	public function moveCollideX(body:Body):Bool
	{
		return true;
	}

	/**
	 * When you collide with an Body on the y-axis with moveTo() or moveBy()
	 * the engine call this function. Override it to detect and change the
	 * behaviour of collisions.
	 *
	 * @param	e	The Body you collided with.
	 *
	 * @return	If there was a collision.
	 */
	public function moveCollideY(body:Body):Bool
	{
		return true;
	}

	function normalizeThickness(point:Vector2, thickness:Float):Void 
    {		
		if (point.x == 0 && point.y == 0)
			return;		
        else 
        {		
			var norm = thickness / Math.sqrt(point.x * point.x + point.y * point.y);
            
			point.x *= norm;
			point.y *= norm;			
		}		
	}
}