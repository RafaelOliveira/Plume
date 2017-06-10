package plume.input;

import kha.input.Keyboard as KhaKeyboard;

class Keyboard implements Input
{
	var keysPressed:Map<Int, Bool>;
	var keysDown:Map<Int, Bool>;
	var keysUp:Map<Int, Bool>;
	var keyCount:Int = 0;
	var keysJustPressed:Bool;

	static var instance:Keyboard;

	function new():Void
	{
		KhaKeyboard.get(0).notify(onKeyDown, onUpKey);

		keysPressed = new Map<Int, Bool>();
		keysDown = new Map<Int, Bool>();
		keysUp = new Map<Int, Bool>();
		keysJustPressed = false;
	}

	public static function get():Keyboard
	{
		if (instance == null)
			instance = new Keyboard();

		return instance;
	}

	function onKeyDown(key:Int):Void
	{
		keysPressed.set(key, true);
		keysDown.set(key, true);

		keyCount++;
		keysJustPressed = true;
	}

	function onUpKey(key:Int):Void
	{
		keysUp.set(key, true);
		keysDown.set(key, false);

		keyCount--;
	}

	@:noCompletion
	public function update():Void
	{
		for (key in keysPressed.keys())
			keysPressed.remove(key);

		for (key in keysUp.keys())
			keysUp.remove(key);

		keysJustPressed = false;
	}

	inline public function isDown(key:Int):Bool
	{
		return keysDown.get(key);
	}

	inline public function isUp(key:Int):Bool
	{
		return keysUp.exists(key);
	}

	inline public function isPressed(key:Int):Bool
	{
		return keysPressed.exists(key);
	}

	inline public function isAnyDown():Bool
	{
		return (keyCount > 0);
	}

	inline public function isAnyPressed():Bool
	{
		return keysJustPressed;
	}	
}