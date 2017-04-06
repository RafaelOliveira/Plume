package plume;

import kha.System;

#if js
import js.html.Window;
import js.html.CanvasElement;
import js.html.ImageElement;
#end

@:allow(plume.Engine)
class Plm
{
	static var stateList:Map<String, State>;

	public static var state:State;
	public static var dt(default, null):Float = 0;
	public static var windowWidth(default, null):Int;
	public static var windowHeight(default, null):Int;
	public static var gameWidth(default, null):Int;
	public static var gameHeight(default, null):Int;

	private static var shakeTime:Float = 0;
	private static var shakeMagnitude:Int = 0;
	private static var shakeX:Int = 0;
	private static var shakeY:Int = 0;

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

	static function updateWindowSize():Void
	{
		#if js
		if (Engine.canvasUsingClientSize)
		{
			windowWidth = js.Browser.window.innerWidth;
			windowHeight = js.Browser.window.innerHeight;

			var khanvas = kha.SystemImpl.khanvas;
			khanvas.width = windowWidth;
			khanvas.height = windowHeight;
			khanvas.style.width = '${windowWidth}px';
			khanvas.style.height = '${windowHeight}px';
		}
		else
		{
			windowWidth = System.windowWidth();
			windowHeight = System.windowHeight();
		}

		kha.SystemImpl.gl.viewport(0, 0, windowWidth, windowHeight);
		#else
		windowWidth = System.windowWidth();
		windowHeight = System.windowHeight();
		#end

		if (Engine.backbuffer == null)
		{
			gameWidth = windowWidth;
			gameHeight = windowHeight;
		}
		
		gameScale = windowWidth / gameWidth;

		if (state != null)
			state.windowSizeUpdated();
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

	/**
	 * Clamps the value within the minimum and maximum values.
	 * @param	value		The Float to evaluate.
	 * @param	min			The minimum range.
	 * @param	max			The maximum range.
	 * @return	The clamped value.
	 */
	public static function clamp(value:Float, min:Float, max:Float):Float
	{
		if (max > min)
		{
			if (value < min) return min;
			else if (value > max) return max;
			else return value;
		}
		else
		{
			// Min/max swapped
			if (value < max) return max;
			else if (value > min) return min;
			else return value;
		}
	}

	/**
	 * Linear interpolation between two values.
	 * @param	a		First value.
	 * @param	b		Second value.
	 * @param	t		Interpolation factor.
	 * @return	When t=0, returns a. When t=1, returns b. When t=0.5, will return halfway between a and b. Etc.
	 */
	public static inline function lerp(a:Float, b:Float, t:Float = 1):Float
	{
		return a + (b - a) * t;
	}

	/**
	 * Linear interpolation between two colors.
	 * @param	fromColor		First color.
	 * @param	toColor			Second color.
	 * @param	t				Interpolation value. Clamped to the range [0, 1].
	 * return	RGB component-interpolated color value.
	 */
	public static inline function colorLerp(fromColor:Int, toColor:Int, t:Float = 1):Int
	{
		if (t <= 0)
		{
			return fromColor;
		}
		else if (t >= 1)
		{
			return toColor;
		}
		else
		{
			var a:Int = fromColor >> 24 & 0xFF,
				r:Int = fromColor >> 16 & 0xFF,
				g:Int = fromColor >> 8 & 0xFF,
				b:Int = fromColor & 0xFF,
				dA:Int = (toColor >> 24 & 0xFF) - a,
				dR:Int = (toColor >> 16 & 0xFF) - r,
				dG:Int = (toColor >> 8 & 0xFF) - g,
				dB:Int = (toColor & 0xFF) - b;
			a += Std.int(dA * t);
			r += Std.int(dR * t);
			g += Std.int(dG * t);
			b += Std.int(dB * t);
			return a << 24 | r << 16 | g << 8 | b;
		}
	}

	/**
	 * Transfers a value from one scale to another scale. For example, scale(.5, 0, 1, 10, 20) == 15, and scale(3, 0, 5, 100, 0) == 40.
	 * @param	value		The value on the first scale.
	 * @param	min			The minimum range of the first scale.
	 * @param	max			The maximum range of the first scale.
	 * @param	min2		The minimum range of the second scale.
	 * @param	max2		The maximum range of the second scale.
	 * @return	The scaled value.
	 */
	public inline static function scale(value:Float, min:Float, max:Float, min2:Float, max2:Float):Float
	{
		return min2 + ((value - min) / (max - min)) * (max2 - min2);
	}

	public static function shake(magnitude:Int, duration:Float)
	{
		if (shakeTime < duration) shakeTime = duration;
		shakeMagnitude = magnitude;
	}

	/**
	 * Stop the screen from shaking immediately.
	 */
	public static function shakeStop()
	{
		shakeTime = 0;
	}
		
	private inline static function updateScreenShake():Void
	{
		if (shakeTime > 0)
		{
			var sx:Int = Std.random(shakeMagnitude * 2 + 1) - shakeMagnitude;
			var sy:Int = Std.random(shakeMagnitude * 2 + 1) - shakeMagnitude;

			state.camera.x += sx - shakeX;
			state.camera.y += sy - shakeY;

			shakeX = sx;
			shakeY = sy;

			shakeTime -= dt;
			if (shakeTime < 0) shakeTime = 0;
		}
		else if (shakeX != 0 || shakeY != 0)
		{
			state.camera.x -= shakeX;
			state.camera.y -= shakeY;
			shakeX = shakeY = 0;
		}
	}

	#if js
	public static function createScreenshot(mimeType:String = 'image/png'):Void
	{		
		var canvas = kha.SystemImpl.khanvas;

		var screenshotCanvas:CanvasElement = cast js.Browser.document.createElement('canvas');
		screenshotCanvas.width = canvas.width;
		screenshotCanvas.height = canvas.height;

		var renderContext = screenshotCanvas.getContext('2d');		
		renderContext.drawImage(canvas, 0, 0, canvas.width, canvas.height);

		var base64Image = screenshotCanvas.toDataURL(mimeType);

		var newWindow = js.Browser.window.open(null, '_blank');
		
		if (newWindow != null)
		{
			adjustScreenshotWindow(newWindow);

			var img:ImageElement = cast newWindow.document.createElement('img');
			img.src = base64Image;
			newWindow.document.body.appendChild(img);
		}
		else
			trace('It wasn\'t possible to create a new window for the screenshot');
	}

	static function adjustScreenshotWindow(window:Window):Void
	{
		window.document.body.style.margin = '0px';
		window.document.body.style.padding = '0px';
		window.document.body.style.height = '100%';
		window.document.body.style.overflow = 'hidden';		
		window.document.documentElement.style.margin = '0px';
		window.document.documentElement.style.padding = '0px';
		window.document.documentElement.style.height = '100%';
		window.document.documentElement.style.overflow = 'hidden';
	}
	#end
}