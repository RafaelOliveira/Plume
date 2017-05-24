package plume.input;

import kha.input.Surface;
import plume.Plm;

class Touch implements Input
{
	inline static var MAX_TOUCHES:Int = 10;

	var touchList:Array<TouchData>;

	static var instance:Touch;

	function new():Void
	{
		Surface.get().notify(touchStart, touchEnd, touchMove);

		touchList = new Array<TouchData>();

		for (i in 0...MAX_TOUCHES)
			touchList.push(new TouchData(0, 0));
	}

	public static function get():Touch
	{
		if (instance == null)
			instance = new Touch();

		return instance;
	}

	@:noCompletion
	public function update():Void
	{
		for (touch in touchList)
			touch.pressed = false;
	}

	function touchStart(index:Int, x:Int, y:Int):Void
	{
		if (index < MAX_TOUCHES)
		{
			var th = touchList[index];

			if (th == null)
				th = new TouchData(0, 0);

			th.x = Std.int(x / Plm.gameScale);
			th.y = Std.int(y / Plm.gameScale);
			th.pressed = true;
			th.down = true;
		}
	}

	function touchEnd(index:Int, x:Int, y:Int):Void
	{
		if (index < MAX_TOUCHES)
		{
			var th = touchList[index];

			if (th != null)
			{
				if (index == touchList.length - 1)
					touchList.splice(index, 1);
				else
				{
					th.x = 0;
					th.y = 0;
					th.down = false;
					th.pressed = false;
				}
			}
		}
	}
	
	function touchMove(index:Int, x:Int, y:Int):Void
	{
		if (index < MAX_TOUCHES)
		{
			var th = touchList[index];

			if (th != null)
			{
				th.x = Std.int(x / Plm.gameScale);
				th.y = Std.int(y / Plm.gameScale);
				th.down = true;
			}
		}
	}

	inline public function getAll():Array<TouchData>
	{		
		return touchList;		
	}

	public function isDownRect(x:Float, y:Float, w:Int, h:Int):Bool
	{		
		for (touch in touchList)
		{
			if (touch.down && Plm.pointInside(touch.x, touch.y, x, y, w, h))
				return true;
		}	

		return false;
	}

	public function isPressedRect(x:Float, y:Float, w:Int, h:Int):Bool
	{		
		for (touch in touchList)
		{
			if (touch.pressed && Plm.pointInside(touch.x, touch.y, x, y, w, h))
				return true;
		}

		return false;
	}
}