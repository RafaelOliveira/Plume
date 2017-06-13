package plume.input;

import haxe.ds.Vector;
import kha.Scheduler;
import kha.input.Mouse;
import kha.math.Vector2;
import plume.Plm;

class Mouse implements Input
{
	inline static var MAX_BUTTONS = 3;

	/** x not scaled */
	public var rawX(default, null):Int = 0;

	/** y not scaled */
	public var rawY(default, null):Int = 0;

	/** x scaled to the backbuffer */
	public var x(default, null):Int = 0;

	/** y scaled to the backbuffer */
	public var y(default, null):Int = 0;

	/** last x position when a mouse click started, scaled to the backbuffer */
	public var sx(default, null):Int = 0;

	/** last y position when a mouse click started, scaled to the backbuffer */
	public var sy(default, null):Int = 0;

	/** delta of x */
	public var dx(default, null):Int = 0;

	/** delta of y */
	public var dy(default, null):Int = 0;

	public var durationMouseDown(default, null):Float = 0;

	var mouseDownStartTime:Float;

	var mousePressed:Vector<Bool>;
	var mouseDown:Vector<Bool>;
	var mouseUp:Vector<Bool>;
	var mouseCount:Int = 0;
	var mouseJustPressed:Bool = false;

	static var instance:Mouse;

	function new():Void
	{		
		kha.input.Mouse.get().notify(onMouseStart, onMouseEnd, onMouseMove, onMouseWheel);

		mousePressed = new Vector(MAX_BUTTONS);
		mouseDown = new Vector(MAX_BUTTONS);
		mouseUp = new Vector(MAX_BUTTONS);

		for (i in 0...MAX_BUTTONS)
		{
			mousePressed[i] = false;
			mouseDown[i] = false;
			mouseUp[i] = false;
		}
	}

	public static function get():Mouse
	{
		if (instance == null)
			instance = new Mouse();

		return instance;
	}

	@:noCompletion
	public function update():Void
	{
		for (i in 0...MAX_BUTTONS)
		{
			mousePressed[i] = false;
			mouseUp[i] = false;
		}			

		mouseJustPressed = false;
	}

	function onMouseStart(index:Int, x:Int, y:Int):Void
	{
		if (index < MAX_BUTTONS)
		{
			updateMouseData(x, y, 0, 0);

			sx = Std.int(x * Plm.gameScale);
			sy = Std.int(y * Plm.gameScale);

			mousePressed[index] = true;
			mouseDown[index] = true;

			mouseCount++;

			mouseJustPressed = true;

			mouseDownStartTime = Scheduler.time();
		}
	}

	function onMouseEnd(index:Int, x:Int, y:Int):Void
	{
		if (index < MAX_BUTTONS)
		{
			updateMouseData(x, y, 0, 0);

			mouseUp[index] = true;
			mouseDown[index] = false;

			mouseCount--;

			durationMouseDown = Scheduler.time() - mouseDownStartTime;
		}
	}

	function onMouseMove(x:Int, y:Int, dx:Int, dy:Int):Void
	{
		updateMouseData(x, y, dx, dy);
	}

	function updateMouseData(x:Int, y:Int, dx:Int, dy:Int):Void
	{
		rawX = x;
		rawY = y;
		this.x = Std.int(x / Plm.gameScale);
		this.y = Std.int(y / Plm.gameScale);
		this.dx = Std.int(dx / Plm.gameScale);
		this.dy = Std.int(dy / Plm.gameScale);		
	}

	function onMouseWheel(delta:Int):Void
	{
		// TODO
		trace("onMouseWheel : " + delta);
	}

	inline public function worldPosX(cameraIndex:Int):Int
	{
		return Std.int(x + Plm.state.cameras[cameraIndex].x);
	}

	inline public function worldPosY(cameraIndex:Int):Int
	{
		return Std.int(y + Plm.state.cameras[cameraIndex].y);
	}

	inline public function isPressed(index:Int = 0):Bool
	{
		return mousePressed[index];
	}

	inline public function isDown(index:Int = 0):Bool
	{
		return mouseDown[index];
	}

	inline public function isUp(index:Int = 0):Bool
	{
		return mouseUp[index];
	}

	inline public function isAnyDown():Bool
	{
		return mouseCount > 0;
	}

	inline public function isAnyPressed():Bool
	{
		return mouseJustPressed;
	}

	inline public function isPressedRect(index:Int, x:Float, y:Float, w:Int, h:Int):Bool
	{
		return mousePressed[index] && Plm.pointInside(this.x, this.y, x, y, w, h);
	}

	inline public function isDownRect(index:Int, x:Float, y:Float, w:Int, h:Int):Bool
	{
		return mouseDown[index] && Plm.pointInside(this.x, this.y, x, y, w, h);
	}

	public function checkSwipe(distance:Int = 30, timeFrom:Float = 0.1, timeUntil:Float = 0.25):Swipe
	{
		var swipeOcurred = (isDown() && Plm.distance(sx, sy, x, y) > distance
			&& durationMouseDown > timeFrom && durationMouseDown < timeUntil);

		if (swipeOcurred)
			return new Swipe(new Vector2(sx, sy), new Vector2(x, y));
		else
			return null;
	}
}