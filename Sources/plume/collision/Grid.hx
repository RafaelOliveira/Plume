package plume.collision;

import kha.math.Vector2;

class Grid extends Body
{
	public function new(pos:Vector2):Void
	{
		super(pos, null);

		type = Body.GRID;
	}

	override public function collideBody(body:Body, x:Float, y:Float):Body
	{
		return null;
	}
}