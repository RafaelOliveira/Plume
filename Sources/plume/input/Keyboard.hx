package plume.input;

import kha.input.Keyboard as KhaKeyboard;
import kha.Key as KhaKey;

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

	function onKeyDown(key:KhaKey, char:String):Void
	{
		var code:Int = getCode(key);

		if(code == -1)
			code = char.toUpperCase().charCodeAt(0);

		if (code == -1) // no key
			return;

		keysPressed.set(code, true);
		keysDown.set(code, true);

		keyCount++;
		keysJustPressed = true;
	}

	function onUpKey(key:KhaKey, char:String):Void
	{
		var code:Int = getCode(key);

		if (code == -1)
			code = char.toUpperCase().charCodeAt(0);

		if (code == -1) // no key
			return;

		keysUp.set(code, true);
		keysDown.set(code, false);

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

	private function getCode(k:KhaKey):Int
	{
		switch(k)
		{
			case KhaKey.BACKSPACE:
				return Key.BACKSPACE;
			case KhaKey.DEL:
				return Key.DELETE;
			case KhaKey.DOWN:
				return Key.DOWN;
			case KhaKey.UP:
				return Key.UP;
			case KhaKey.LEFT:
				return Key.LEFT;
			case KhaKey.RIGHT:
				return Key.RIGHT;
			case KhaKey.SHIFT:
				return Key.SHIFT;
			case KhaKey.BACK:
			case KhaKey.ESC:
				return Key.ESCAPE;
			case KhaKey.ENTER:
				return Key.ENTER;
			case KhaKey.TAB:
				return Key.TAB;
			case KhaKey.CTRL:
				return Key.CONTROL;
			case KhaKey.ALT:
			case KhaKey.CHAR:
				return -1;
		}

		return -1;
	}
}