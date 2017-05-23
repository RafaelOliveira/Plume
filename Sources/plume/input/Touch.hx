package plume.input;

class Touch 
{
	public var x:Int;
	public var y:Int;
	public var down:Bool;
	public var pressed:Bool;
	
	public function new(x:Int, y:Int):Void
	{
		this.x = x;
		this.y = y;
		this.down = false;
		this.pressed = false;
	}
}