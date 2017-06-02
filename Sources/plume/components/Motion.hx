package plume.components;

import kha.math.Vector2;

class Motion
{
	public var velocity:Vector2;
	public var maxVelocity:Vector2;
	public var acceleration:Vector2;
	public var drag:Vector2;
	
	public function new() 
	{		
		velocity = new Vector2(0, 0);
		acceleration = new Vector2(0, 0);
		drag = new Vector2(0, 0);
		maxVelocity = new Vector2(10000, 10000);
	}	
	
	public function update():Void
	{	
		velocity.x = computeVelocity(velocity.x, acceleration.x, drag.x, maxVelocity.x);
		velocity.y = computeVelocity(velocity.y, acceleration.y, drag.y, maxVelocity.y);				
	}

	function computeVelocity(compVelocity:Float, compAcceleration:Float, compDrag:Float, compMaxVelocity:Float):Float
	{
		if (compAcceleration != 0)
			compVelocity += compAcceleration;
		else if (compDrag != 0)
		{
			if (compVelocity - compDrag > 0)
			{
				compVelocity -= compDrag;
			}
			else if (compVelocity + compDrag < 0)
			{
				compVelocity += compDrag;
			}
			else			
				compVelocity = 0;			
		}

		if ((compVelocity != 0) && (compMaxVelocity != 0))
		{
			if (compVelocity > compMaxVelocity)			
				compVelocity = compMaxVelocity;			
			else if (compVelocity < -compMaxVelocity)			
				compVelocity = -compMaxVelocity;			
		}
		return compVelocity;
	}
}