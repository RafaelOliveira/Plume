package plume.input;

import kha.input.Keyboard as KhaKeyboard;
import kha.input.KeyCode;

class Keyboard implements Input
{
	var keysPressed:Map<KeyCode, Bool>;
	var keysDown:Map<KeyCode, Bool>;
	var keysUp:Map<KeyCode, Bool>;
	var keyCount:Int = 0;
	var keysJustPressed:Bool;

	static var instance:Keyboard;

	function new():Void
	{
		KhaKeyboard.get(0).notify(onKeyDown, onUpKey);

		keysPressed = new Map<KeyCode, Bool>();
		keysDown = new Map<KeyCode, Bool>();
		keysUp = new Map<KeyCode, Bool>();
		keysJustPressed = false;
	}

	public static function get():Keyboard
	{
		if (instance == null)
			instance = new Keyboard();

		return instance;
	}

	function onKeyDown(key:KeyCode):Void
	{
		keysPressed.set(key, true);
		keysDown.set(key, true);

		keyCount++;
		keysJustPressed = true;
	}

	function onUpKey(key:KeyCode):Void
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

	inline public function isDown(key:KeyCode):Bool
	{
		return keysDown.get(key);
	}

	inline public function isUp(key:KeyCode):Bool
	{
		return keysUp.exists(key);
	}

	inline public function isPressed(key:KeyCode):Bool
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