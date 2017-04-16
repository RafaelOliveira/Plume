package plume.input;

import kha.input.Mouse;
import kha.math.Vector2;
import plume.Plm;

class Mouse extends Manager
{
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

	/** x inside the world (adjusted with the camera) */
	public var wx(default, null):Int = 0;

	/** y inside the world (adjusted with the camera) */
	public var wy(default, null):Int = 0;

	public var durationMouseDown(default, null):Float = 0;

	var mouseDownStartTime:Float;

	var mousePressed:Map<Int, Bool>;
	var mouseDown:Map<Int, Bool>;
	var mouseUp:Map<Int, Bool>;
	var mouseCount:Int = 0;
	var mouseJustPressed:Bool = false;

	static var instance:Mouse;

	function new():Void
	{
		super();

		kha.input.Mouse.get().notify(onMouseStart, onMouseEnd, onMouseMove, onMouseWheel);

		mousePressed = new Map<Int, Bool>();
		mouseDown = new Map<Int, Bool>();
		mouseUp = new Map<Int, Bool>();
	}

	public static function get():Mouse
	{
		if (instance == null)
			instance = new Mouse();

		return instance;
	}

	override public function update():Void
	{
		for (key in mousePressed.keys())
			mousePressed.remove(key);

		for (key in mouseUp.keys())
			mouseUp.remove(key);

		mouseJustPressed = false;
	}

	function onMouseStart(index:Int, x:Int, y:Int):Void
	{
		updateMouseData(x, y, 0, 0);

		sx = Std.int(x * Plm.gameScale);
		sy = Std.int(y * Plm.gameScale);

		mousePressed.set(index, true);
		mouseDown.set(index, true);

		mouseCount++;

		mouseJustPressed = true;

		mouseDownStartTime = kha.Scheduler.time();
	}

	function onMouseEnd(index:Int, x:Int, y:Int):Void
	{
		updateMouseData(x, y, 0, 0);

		mouseUp.set(index, true);
		mouseDown.remove(index);

		mouseCount--;

		durationMouseDown = kha.Scheduler.time() - mouseDownStartTime;
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

		if (Plm.state != null)
		{
			wx = Std.int((x + Plm.state.camera.x) / Plm.gameScale);
			wy = Std.int((y + Plm.state.camera.y) / Plm.gameScale);
		}
	}

	function onMouseWheel(delta:Int):Void
	{
		// TODO
		trace("onMouseWheel : " + delta);
	}

	inline public function isPressed(index:Int = 0):Bool
	{
		return mousePressed.exists(index);
	}

	inline public function isDown(index:Int = 0):Bool
	{
		return mouseDown.exists(index);
	}

	inline public function isUp(index:Int = 0):Bool
	{
		return mouseUp.exists(index);
	}

	inline public function isAnyDown():Bool
	{
		return mouseCount > 0;
	}

	inline public function isAnyPressed():Bool
	{
		return mouseJustPressed;
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