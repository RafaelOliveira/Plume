package plume.input;

import kha.math.Vector2;

class Swipe
{
	public var start:Vector2;
	public var end:Vector2;

	public function new(start:Vector2, end:Vector2):Void
	{
		this.start = start;
		this.end = end;
	}
}