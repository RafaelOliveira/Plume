package plume;

import kha.math.Vector2i;
import kha.System;
import kha.Framebuffer;
import kha.Scheduler;
import kha.Scaler;
import kha.Image;
import kha.graphics2.ImageScaleQuality;
import kha.math.Vector2i;
import plume.input.Input;
import plume.input.Keyboard;
import plume.input.Mouse;
import plume.input.Touch;

#if !js
import kha.Display;
#end

@:structInit
class EngineOptions
{	
	@:optional public var fps:Null<Int>;
	@:optional public var bbWidth:Null<Int>;
	@:optional public var bbHeight:Null<Int>;
	@:optional public var highQualityScale:Null<Bool>;
	@:optional public var keyboard:Null<Bool>;
	@:optional public var mouse:Null<Bool>;
	@:optional public var touch:Null<Bool>;
}

@:allow(plume.Plm)
class Engine
{	
	var backbuffer:Image;
	var highQualityScale:Bool;
	var inputs:Array<Input>;	

	var currTime:Float = 0;
	var prevTime:Float = 0;	

	#if js
	static var canvasUsingClientSize:Bool = false;
	static var canvasSizeBeforeFullscreen:Vector2i;
	#end

	static var instance:Engine;

	public function new(?options:EngineOptions):Void
	{
		instance = this;

		var fps:Int = 60;

		if (options != null)
		{
			highQualityScale = options.highQualityScale != null ? options.highQualityScale : false;

			if (options.bbWidth != null && options.bbHeight != null)
				backbuffer = Image.createRenderTarget(options.bbWidth, options.bbHeight);

			if (options.fps != null)
				fps = options.fps;

			inputs = new Array<Input>();

			if (options.keyboard != null && options.keyboard == true)
				inputs.push(Keyboard.get());

			if (options.mouse != null && options.mouse == true)
				inputs.push(Mouse.get());

			if (options.touch != null && options.touch == true)
				inputs.push(Touch.get());
		}
		else		
			highQualityScale = false;		
				
		currTime = Scheduler.time();

		Plm.stateList = new Map<String, State>();		
			
		setupGameWindow();
			
		if (backbuffer != null)
			System.notifyOnRender(renderWithBackbuffer);
		else
			System.notifyOnRender(renderWithFramebuffer);

		Scheduler.addTimeTask(update, 0, 1 / fps);
	}

	function setupGameWindow():Void
	{
		Plm.windowWidth = System.windowWidth();
		Plm.windowHeight = System.windowHeight();

		if (backbuffer != null)
		{
			Plm.gameWidth = backbuffer.width;
			Plm.gameHeight = backbuffer.height;
		}
		else
		{
			Plm.gameWidth = Plm.windowWidth;
			Plm.gameHeight = Plm.windowHeight;
		}

		Plm.gameScale = Plm.windowWidth / Plm.gameWidth;
	}

	function update():Void
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
		if (!canvasUsingClientSize)
			canvasSizeBeforeFullscreen = new Vector2i(System.windowWidth(), System.windowHeight());

		if (Plm.isMobile())
			kha.SystemImpl.khanvas.ontouchstart = function() onMouseDownCanvasFullscreen(0, 0, 0);
		else
			kha.input.Mouse.get().notify(onMouseDownCanvasFullscreen, null, null, null, null);

		kha.SystemImpl.notifyOfFullscreenChange(updateCanvasSize, null);
		#else
		kha.SystemImpl.requestFullscreen();
		#end
	}

	#if js
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

		canvasUsingClientSize = true;
	}

	static function onMouseDownCanvasFullscreen(button:Int, x:Int, y:Int):Void
	{
		if (!kha.SystemImpl.isFullscreen())		
			kha.SystemImpl.requestFullscreen();		
	}
	
	static function updateCanvasSize():Void
	{		
		if (canvasUsingClientSize || js.Browser.document.fullscreenEnabled)
		{
			Plm.windowWidth = js.Browser.window.innerWidth;
			Plm.windowHeight = js.Browser.window.innerHeight;			
		}
		else
		{
			Plm.windowWidth = canvasSizeBeforeFullscreen.x;
			Plm.windowHeight = canvasSizeBeforeFullscreen.y;
		}

		var khanvas = kha.SystemImpl.khanvas;
		khanvas.width = Plm.windowWidth;
		khanvas.height = Plm.windowHeight;
		khanvas.style.width = '${Plm.windowWidth}px';
		khanvas.style.height = '${Plm.windowHeight}px';

		kha.SystemImpl.gl.viewport(0, 0, Plm.windowWidth, Plm.windowHeight);		

		if (instance.backbuffer == null)
		{
			Plm.gameWidth = Plm.windowWidth;
			Plm.gameHeight = Plm.windowHeight;
		}
		
		Plm.gameScale = Plm.windowWidth / Plm.gameWidth;

		if (Plm.state != null)
			Plm.state.windowSizeUpdated();
	}				
	#end	
}