package plume;
import kha.System;
import kha.Framebuffer;
import kha.Scheduler;
import kha.Scaler;
import kha.Image;
import kha.graphics2.ImageScaleQuality;
import kha.math.Vector2i;
import plume.input.Manager;

@:structInit
class EngineOptions
{	
	@:optional public var bbWidth:Null<Int>;
	@:optional public var bbHeight:Null<Int>;
	@:optional public var highQualityScale:Null<Bool>;	
}

@:allow(plume.Plm)
class Engine
{	
	var backbuffer:Image;
	var highQualityScale:Bool;
	var inputs:Array<Manager>;

	var currTime:Float = 0;
	var prevTime:Float = 0;	

	#if js
	var canvasUsingClientSize:Bool = false;
	#end

	static var instance:Engine;

	public function new(options:EngineOptions):Void
	{
		instance = this;		

		highQualityScale = options.highQualityScale != null ? options.highQualityScale : false;				

		inputs = new Array<Manager>();

		currTime = Scheduler.time();

		if (options.bbWidth != null && options.bbHeight != null)
		{
			backbuffer = Image.createRenderTarget(options.bbWidth, options.bbHeight);

			Plm.init(true, backbuffer.width, backbuffer.height);
			System.notifyOnRender(renderWithBackbuffer);
		}
		else
		{
			Plm.init(false, 0, 0);
			System.notifyOnRender(renderWithFramebuffer);
		}

		Scheduler.addTimeTask(update, 0, 1 / 60);		
	}

	public function update():Void
	{
		prevTime = currTime;
		currTime = Scheduler.time();
		Plm.dt = currTime - prevTime;

		if (Plm.state != null)
		{
			Plm.state.update();

			for (input in inputs)
				input.update();

			Plm.updateScreenShake();
		}
	}

	function renderWithFramebuffer(framebuffer:Framebuffer):Void
	{
		if (Plm.state != null)
		{
			framebuffer.g2.begin(false);
			Plm.state.render(framebuffer.g2);
			framebuffer.g2.end();
		}
	}

	function renderWithBackbuffer(framebuffer:Framebuffer):Void
	{
		if (Plm.state != null)
		{
			backbuffer.g2.begin(false);
			Plm.state.render(backbuffer.g2);
			backbuffer.g2.end();

			framebuffer.g2.begin();
			
			if (highQualityScale)
				framebuffer.g2.imageScaleQuality = ImageScaleQuality.High;
			#if js
			else
				framebuffer.g2.imageScaleQuality = ImageScaleQuality.Low;
			#end

			Scaler.scale(backbuffer, framebuffer, System.screenRotation);
			framebuffer.g2.end();
		}
	}

	public function enableInput(options:Int):Void
	{
		if (options & Manager.KEYBOARD == Manager.KEYBOARD)
			inputs.push(plume.input.Keyboard.get());

		if (options & Manager.MOUSE == Manager.MOUSE)
			inputs.push(plume.input.Mouse.get());

		/*if (options & Manager.TOUCH == Manager.TOUCH)
			inputs.push(new plume.input.Touch());

		if (options & Manager.GAMEPAD == Manager.GAMEPAD)
			inputs.push(plume.input.GamePad.getManager());*/
	}

	public static function getSizePrimaryScreen():Vector2i
	{
		var size:Vector2i;

		#if js
		size = new Vector2i(js.Browser.window.innerWidth, js.Browser.window.innerHeight);
		#else
		var count = Display.count;
		var idxPrimary = 0;

		for (i in 0...count)
		{
			if (Display.isPrimary(i))
			{
				idxPrimary = i;
				break;
			}
		}

		size = new Vector2i(Display.width(idxPrimary), Display.height(idxPrimary));
		#end

		if (size.x <= 0 || size.y <= 0)
		{
			trace('The size of the screen is undefined. Returning a size of 800x600.');

			size.x = 800;
			size.y = 600;
		}

		return size;
	}
	
	public static function requestFullScreen():Void
	{
		#if js
		if (isJsMobile())
			kha.SystemImpl.khanvas.ontouchstart = function() onMouseDownFullscreen(0, 0, 0);
		else
			kha.input.Mouse.get().notify(onMouseDownFullscreen, null, null, null, null);

		kha.SystemImpl.notifyOfFullscreenChange(Plm.updateWindowSize, null);
		#else
		kha.SystemImpl.requestFullscreen();
		#end		
	}

	#if js
	static function onMouseDownFullscreen(button:Int, x:Int, y:Int):Void
	{
		if (!kha.SystemImpl.isFullscreen())		
			kha.SystemImpl.requestFullscreen();		
	}

	/*static function setCanvasScaleQuality(value:Bool):Void
	{
		var canvas:Dynamic = kha.SystemImpl.khanvas;

		if (canvas != null)
		{
			canvas.mozImageSmoothingEnabled = value;
			canvas.webkitImageSmoothingEnabled = value;
			canvas.msImageSmoothingEnabled = value;
			canvas.imageSmoothingEnabled = value;
		}
	}*/

	public static function setCanvasToClientSize(canvasName:String = 'khanvas'):Void
	{		
		js.Browser.document.body.style.margin = '0px';
		js.Browser.document.body.style.padding = '0px';
		js.Browser.document.body.style.height = '100%';
		js.Browser.document.body.style.overflow = 'hidden';		
		js.Browser.document.documentElement.style.margin = '0px';
		js.Browser.document.documentElement.style.padding = '0px';
		js.Browser.document.documentElement.style.height = '100%';
		js.Browser.document.documentElement.style.overflow = 'hidden';

		var khanvas:js.html.CanvasElement = kha.SystemImpl.khanvas != null ? 
			kha.SystemImpl.khanvas : cast js.Browser.document.getElementById(canvasName);

		var w:Int = js.Browser.window.innerWidth;
		var h:Int = js.Browser.window.innerHeight;

		khanvas.width = w;
		khanvas.height = h;
		khanvas.style.width = Std.string(w);
		khanvas.style.height = Std.string(h);

		Engine.instance.canvasUsingClientSize = true;
	}	

	public static function isJsMobile():Bool
	{
		var mobile = ['iphone', 'ipad', 'android', 'blackberry', 'nokia', 'opera mini', 'windows mobile', 'windows phone', 'iemobile'];
		for (i in 0...mobile.length)
		{
			if (js.Browser.navigator.userAgent.toLowerCase().indexOf(mobile[i].toLowerCase()) > 0)
				return true;
		}

		return false;
	}
	#end

	public static function isMobile():Bool
	{
		#if js
		return isJsMobile();
		#elseif (sys_android || sys_android_native || sys_ios)
		return true;		
		#end

		return false;
	}
}