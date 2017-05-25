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

	var warningState:State;
	var activeState:State;
	var warningStateActive:Bool;
	var rightOrientation:Int;
	var actualOrientation:Int;	

	public function new(warningState:State, rightOrientation:Int):Void
	{
		this.warningState = warningState;
		this.rightOrientation = rightOrientation;
		warningStateActive = false;

		Engine.setCanvasToClientSize();
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