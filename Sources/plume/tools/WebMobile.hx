#if (js && web_mobile)
package plume.tools;

import js.Browser;
import plume.Engine;
import plume.State;
import plume.Plm;

class WebMobile
{
	public inline static var PORTRAIT:Int = 0;
	public inline static var LANDSCAPE:Int = 1;

	var baseWidth:Int;
	var baseHeight:Int;

	public var bbWidth:Int;
	public var bbHeight:Int;

	var warningState:State;
	var activeState:State;
	var warningStateActive:Bool;
	var rightOrientation:Int;
	var actualOrientation:Int;

	public function new(warningState:State, rightOrientation:Int, baseWidth:Int, baseHeight:Int):Void
	{
		this.warningState = warningState;
		this.rightOrientation = rightOrientation;
		warningStateActive = false;

		this.baseWidth = baseWidth;
		this.baseHeight = baseHeight;

		Engine.setCanvasToClientSize();
		
		if (baseWidth > 0 && baseHeight > 0)
			calculateBackbufferSize();
	}

	function calculateBackbufferSize():Void
	{
		var windowWidth = Browser.window.innerWidth;
		var windowHeight = Browser.window.innerHeight;

		var scaleFactor = getScaleFactor(windowWidth, windowHeight);

		bbWidth = Math.ceil(windowWidth / scaleFactor);
		bbHeight = Math.ceil(windowHeight / scaleFactor);		
	}

	function getScaleFactor(windowWidth:Int, windowHeight:Int):Float
	{
		var ratioX:Float = 0;
		var ratioY:Float = 0;
		var orientation = getOrientation();

		if (Plm.isMobile())
		{
			if (orientation == rightOrientation)
			{
				ratioX = windowWidth / baseWidth;
				ratioY = windowHeight / baseHeight;
			}
			else
			{
				ratioX = windowWidth / baseHeight;
				ratioY = windowHeight / baseWidth;
			}
		}
		else
		{
			ratioX = windowWidth / baseWidth;
			ratioY = windowHeight / baseHeight;
		}

        return Math.min(ratioX, ratioY);
	}

	public function update():Void
	{
		actualOrientation = getOrientation();

		if (actualOrientation != rightOrientation && !warningStateActive)
		{
			if (Plm.state != null)
				activeState = Plm.state;

			Plm.state = warningState;
			warningStateActive = true;

			updateGame();
		}
		else if (actualOrientation == rightOrientation && warningStateActive)
		{
			if (activeState != null)
				Plm.state = activeState;

			warningStateActive = false;

			updateGame();
		}
	}

	function updateGame():Void
	{
		if (baseWidth > 0 && baseHeight > 0)
			calculateBackbufferSize();

		Engine.updateCanvasSize(Browser.window.innerWidth, Browser.window.innerHeight);
		Engine.updateGameSize(Browser.window.innerWidth, Browser.window.innerHeight);
	}

	public inline static function getOrientation():Int
	{		
		if (Browser.window.innerHeight > Browser.window.innerWidth)		
			return PORTRAIT;
		else
			return LANDSCAPE;		
	}
}
#end