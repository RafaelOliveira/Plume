package plume;

import kha.System;

@:allow(plume.Engine)
class Plm
{
	static var stateList:Map<String, State>;

	public static var state:State;
	public static var windowWidth(default, null):Int;
	public static var windowHeight(default, null):Int;
	public static var gameWidth(default, null):Int;
	public static var gameHeight(default, null):Int;

	public static var gameScale(default, null):Float;

	static function init(useBackbuffer:Bool, bbWidth:Int, bbHeight:Int):Void
	{
		stateList = new Map<String, State>();

		windowWidth = System.windowWidth();
		windowHeight = System.windowHeight();

		if (useBackbuffer)
		{
			gameWidth = bbWidth;
			gameHeight = bbHeight;
		}
		else
		{
			gameWidth = windowWidth;
			gameHeight = windowHeight;
		}

		gameScale = windowWidth / gameWidth;
	}

	public static function addState(state:State, name:String, go:Bool = false):Void
	{
		stateList.set(name, state);

		if (go)
		{
			Plm.state = state;
			Plm.state.init();
		}
	}

	public static function switchState(name:String):Bool
	{
		var state = stateList.get(name);

		if (state != null)
		{
			Plm.state = state;
			Plm.state.init();
			return true;
		}
		else
			return false;
	}

	/**
	 * Find the distance between two points.
	 * @param	x1		The first x-position.
	 * @param	y1		The first y-position.
	 * @param	x2		The second x-position.
	 * @param	y2		The second y-position.
	 * @return	The distance.
	 */
	public static inline function distance(x1:Float, y1:Float, x2:Float = 0, y2:Float = 0):Float
	{
		return Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
	}

	public static function pointInside(px:Float, py:Float, x:Float, y:Float, w:Int, h:Int):Bool
	{
		if (px > x && px < (x + w) && py > y && py < (y + h))
			return true;
		else
			return false;
	}

	public static function rectCollision(x1:Float, y1:Float, w1:Int, h1:Int, x2:Float, y2:Float, w2:Int, h2:Int):Bool
	{
		if (x1 + w1 > x2 &&
			y1 + h1 > y2 &&
			x1 < x2 + w2 &&
			y1 < y2 + h2)
			return true;
		else
			return false;
	}
}