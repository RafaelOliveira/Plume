package plume.input;

import kha.Scheduler;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.Key as KhaKey;
import kha.math.Vector2;
import plume.Plm;

@:allow(plume.Engine)
class Input
{
	inline static var KEYBOARD:Int = 1;
	inline static var MOUSE:Int = 2;
	inline static var TOUCH:Int = 4;
	inline static var GAMEPAD:Int = 8;

	static var keyboardEnabled:Bool = false;
	static var mouseEnabled:Bool = false;

	static var keysPressed:Map<Int, Bool>;
	static var keysDown:Map<Int, Bool>;
	static var keysUp:Map<Int, Bool>;
	static var keyCount:Int = 0;
	static var keysJustPressed:Bool = false;

	static var mouseBtPressed:Map<Int, Bool>;
	static var mouseBtDown:Map<Int, Bool>;
	static var mouseBtUp:Map<Int, Bool>;
	static var mouseWheelRotated:Bool = false;
	static var mouseWheelValue:Int = 0;
	static var mouseCount:Int = 0;
	static var mouseJustPressed:Bool = false;

	/** x not scaled */
	public static var mouseRawX(default, null):Int = 0;

	/** y not scaled */
	public static var mouseRawY(default, null):Int = 0;

	/** x scaled to the backbuffer */
	public static var mouseX(default, null):Int = 0;

	/** y scaled to the backbuffer */
	public static var mouseY(default, null):Int = 0;

	/** the x position when a mouse click started, scaled to the backbuffer */
	public static var mouseSx(default, null):Int = 0;

	/** the y position when a mouse click started, scaled to the backbuffer */
	public static var mouseSy(default, null):Int = 0;

	/** delta of x */
	public static var mouseDx(default, null):Int = 0;

	/** delta of y */
	public static var mouseDy(default, null):Int = 0;

	/** x inside the world (adjusted with the camera) */
	public static var mouseWx(default, null):Int = 0;

	/** y inside the world (adjusted with the camera) */
	public static var mouseWy(default, null):Int = 0;

	public static var durationMouseDown(default, null):Float = 0;

	static var mouseDownStartTime:Float;

	static function enable(options:Int):Void
	{
		if (options & KEYBOARD == KEYBOARD)
		{
			Keyboard.get(0).notify(onKeyDown, onKeyUp);

			keysPressed = new Map<Int, Bool>();
			keysDown = new Map<Int, Bool>();
			keysUp = new Map<Int, Bool>();
			keysJustPressed = false;

			keyboardEnabled = true;
		}	

		if (options & MOUSE == MOUSE)
		{
			Mouse.get().notify(onMouseStart, onMouseEnd, onMouseMove, onMouseWheel);

			mouseBtPressed = new Map<Int, Bool>();
			mouseBtDown = new Map<Int, Bool>();
			mouseBtUp = new Map<Int, Bool>();

			mouseEnabled = true;
		}

		/*if (options & Manager.TOUCH == Manager.TOUCH)
			inputs.push(new plume.input.Touch());

		if (options & Manager.GAMEPAD == Manager.GAMEPAD)
			inputs.push(plume.input.GamePad.getManager());*/
	}

	static function onKeyDown(key:KhaKey, char:String):Void
	{
		var code:Int = getKeyCode(key);

		if(code == -1)
			code = char.toUpperCase().charCodeAt(0);

		if (code == -1) // no key
			return;

		keysPressed.set(code, true);
		keysDown.set(code, true);

		keyCount++;
		keysJustPressed = true;
	}

	static function onKeyUp(key:KhaKey, char:String):Void
	{
		var code:Int = getKeyCode(key);

		if (code == -1)
			code = char.toUpperCase().charCodeAt(0);

		if (code == -1) // no key
			return;

		keysUp.set(code, true);
		keysDown.set(code, false);

		keyCount--;
	}

	static function getKeyCode(k:KhaKey):Int
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

	static function onMouseStart(index:Int, x:Int, y:Int):Void
	{	
		mouseSx = Std.int(x / Plm.gameScale);
		mouseSy = Std.int(y / Plm.gameScale);

		updateMouseData(x, y, 0, 0);

		mouseBtPressed.set(index, true);
		mouseBtDown.set(index, true);

		mouseCount++;

		mouseJustPressed = true;

		mouseDownStartTime = Scheduler.time();
	}

	static function onMouseEnd(index:Int, x:Int, y:Int):Void
	{
		updateMouseData(x, y, 0, 0);

		mouseBtUp.set(index, true);
		mouseBtDown.remove(index);

		mouseCount--;

		durationMouseDown = Scheduler.time() - mouseDownStartTime;
	}

	static function onMouseMove(x:Int, y:Int, dx:Int, dy:Int):Void
	{
		updateMouseData(x, y, dx, dy);
	}

	static function onMouseWheel(delta:Int):Void
	{
		mouseWheelRotated = true;
		mouseWheelValue = delta;		
	}

	static function updateMouseData(x:Int, y:Int, dx:Int, dy:Int):Void
	{
		mouseRawX = x;
		mouseRawY = y;
		mouseX = Std.int(x / Plm.gameScale);
		mouseY = Std.int(y / Plm.gameScale);
		mouseDx = Std.int(dx / Plm.gameScale);
		mouseDy = Std.int(dy / Plm.gameScale);

		if (Plm.state != null)
		{
			mouseWx = Std.int((x + Plm.state.camera.x) / Plm.gameScale);
			mouseWy = Std.int((y + Plm.state.camera.y) / Plm.gameScale);
		}
	}

	static function update():Void
	{
		if (keyboardEnabled)
		{
			for (key in keysPressed.keys())
				keysPressed.remove(key);

			for (key in keysUp.keys())
				keysUp.remove(key);

			keysJustPressed = false;
		}

		if (mouseEnabled)
		{
			for (button in mouseBtPressed.keys())
			mouseBtPressed.remove(button);

			for (button in mouseBtUp.keys())
				mouseBtUp.remove(button);

			mouseJustPressed = false;
			mouseWheelRotated = false;
		}
	}

	inline static public function keyDown(key:Int):Bool
	{
		return keyboardEnabled && keysDown.get(key);
	}

	inline static public function keyUp(key:Int):Bool
	{
		return keyboardEnabled && keysUp.exists(key);
	}

	inline static public function keyPressed(key:Int):Bool
	{
		return keyboardEnabled && keysPressed.exists(key);
	}

	inline static public function anyKeyDown():Bool
	{
		return keyboardEnabled && keyCount > 0;
	}

	inline static public function anyKeyPressed():Bool
	{
		return keyboardEnabled && keysJustPressed;
	}

	inline static public function mousePressed(index:Int = 0):Bool
	{
		return mouseEnabled && mouseBtPressed.exists(index);
	}

	inline static public function mouseDown(index:Int = 0):Bool
	{
		return mouseEnabled && mouseBtDown.exists(index);
	}

	inline static public function mouseUp(index:Int = 0):Bool
	{
		return mouseEnabled && mouseBtUp.exists(index);
	}

	inline static public function anyMouseDown():Bool
	{
		return mouseEnabled && mouseCount > 0;
	}

	inline static public function anyMousePressed():Bool
	{
		return mouseEnabled && mouseJustPressed;
	}

	public static function checkSwipe(distance:Int = 30, timeFrom:Float = 0.1, timeUntil:Float = 0.25):Swipe
	{
		var swipeOcurred = (mouseDown() && Plm.distance(mouseSx, mouseSy, mouseX, mouseY) > distance
			&& durationMouseDown > timeFrom && durationMouseDown < timeUntil);

		if (swipeOcurred)
			return new Swipe(new Vector2(mouseSx, mouseSy), new Vector2(mouseX, mouseY));
		else
			return null;
	}
}