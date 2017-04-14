package plume.math;

class Rectangle 
{
	public var x: Float;
	public var y: Float;
	public var width: Float;
	public var height: Float;

	public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0):Void 
    {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	public function setPos(x:Int, y:Int):Void 
    {
		this.x = x;
		this.y = y;
	}

	public function moveX(dx:Int):Void 
    {
		x += dx;
	}

	public function moveY(dy:Int):Void 
    {
		y += dy;
	}

	public function collision(rect:Rectangle):Bool 
    {
		var a: Bool;
		var b: Bool;

		if (x < rect.x) 
			a = rect.x < x + width;
		else 
			a = x < rect.x + rect.width;

		if (y < rect.y) 
			b = rect.y < y + height;
		else 
			b = y < rect.y + rect.height;

		return a && b;
	}

	public function collisionProjected(tx:Float, ty:Float, rect:Rectangle, rx:Float, ry:Float):Bool 
    {
		var a: Bool;
		var b: Bool;

		if (x + tx < rect.x + rx) 
			a = rect.x + rx < x + tx + width;
		else 
			a = x + tx < rect.x + rx + rect.width;

		if (y + ty < rect.y + ry) 
			b = rect.y + ry < y + ty + height;
		else 
			b = y + ty < rect.y + ry + rect.height;

		return a && b;
	}
    
    public function pointInside(px:Float, py:Float):Bool
    {
        if (px > x && px < (x + width) && py > y && py < (y + height))
            return true;
        else
            return false;
    }

	public function rectInside(rect:Rectangle):Bool
	{
		if (rect.width <= width && rect.height <= height
			&& ((rect.x == x && rect.y == y) || (rect.x > x && (rect.x + rect.width) < (x + width) && (rect.y + rect.height) < (y + height))
		))
			return true;
		else
			return false;
	}

	public function intersection(rect:Rectangle):Rectangle
	{
		var nx:Float = 0; 
		var ny:Float = 0;
		var nw:Float = 0; 
		var nh:Float = 0;

		if (x < rect.x)
		{
			nx = rect.x;
			nw = Std.int((x + width) - rect.x);  
		}
		else
		{
			nx = x;
			
			if ((x + width) < (rect.x + rect.width))
				nw = width;
			else
				nw = Std.int((rect.x + rect.width) - x);
		}

		if (y < rect.y)
		{
			ny = rect.y;
			nh = Std.int((y + height) - rect.y);
		}
		else
		{
			ny = y;

			if ((y + height) < (rect.y + rect.height))
				nh = height;
			else
				nh = Std.int((rect.y + rect.height) - y);
		}

		return new Rectangle(nx, ny, nw, nh);
	}

	public function separate(rect:Rectangle):Void
	{
		if (collision(rect))
		{
			var inter = intersection(rect);

			// collided horizontally
			if (inter.height > inter.width)
			{
				// collided from the right
				if ((x + width) > rect.x && (x + width) < (rect.x + rect.width))
					x = rect.x - width;
				// collided from the left
				else
					x = rect.x + rect.width;
			}
			// collided vertically
			else
			{
				// collided from the top
				if ((y + height) > rect.y && (y + height) < (rect.y + rect.height))
					y = rect.y - height;
				// collided from the bottom
				else
					y = rect.y + rect.height;
			}
		}
	}
}