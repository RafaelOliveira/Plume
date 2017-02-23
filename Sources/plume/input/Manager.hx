package plume.input;

@:allow(plume.Engine)
class Manager
{
	public inline static var KEYBOARD:Int = 1;
	public inline static var MOUSE:Int = 2;
	public inline static var TOUCH:Int = 4;
	public inline static var GAMEPAD:Int = 8;

	public function new():Void {}

	function update():Void {}
}