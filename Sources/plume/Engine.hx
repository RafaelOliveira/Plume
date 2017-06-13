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

#if (js && !sys_debug_html5 && web_mobile)
import plume.tools.WebMobile;
#end

#if !js
import kha.Display;
#else
import js.Browser;
import kha.SystemImpl;
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

	#if (js && !sys_debug_html5 && web_mobile)
	@:optional public var warningState:State;
	@:optional public var rightOrientation:Int;
	#end
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

	#if (js && !sys_debug_html5 && web_mobile)
	var webMobile:WebMobile;
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

			#if (js && !sys_debug_html5 && web_mobile)
			if (options.warningState != null && options.rightOrientation != null)
				webMobile = new WebMobile(options.warningState, options.rightOrientation);
			#end
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

		#if (js && !sys_debug_html5 && web_mobile)
		if (webMobile != null)
			Scheduler.addTimeTask(updateWebMobile, 0, 1 / fps);
		else
		#end
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
		updateDeltaTime();
		updateState();
	}

	#if (js && !sys_debug_html5 && web_mobile)
	function updateWebMobile()
	{
		updateDeltaTime();
		webMobile.update();
		updateState();
	}
	#end

	inline function updateDeltaTime():Void
	{
		prevTime = currTime;
		currTime = Scheduler.time();
		Plm.dt = currTime - prevTime;
	}

	inline function updateState():Void
	{
		if (Plm.state != null)
		{
			Plm.state.update();			
			
			for (input in inputs)
				input.update();

			Plm.state.updateCameras();
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

		kha.SystemImpl.notifyOfFullscreenChange(onFullscreenChange, null);
		#else
		kha.SystemImpl.requestFullscreen();
		#end
	}

	#if js
	public static function setCanvasToClientSize():Void
	{		
		Browser.document.body.style.margin = '0px';
		Browser.document.body.style.padding = '0px';
		Browser.document.body.style.height = '100%';
		Browser.document.body.style.overflow = 'hidden';		
		Browser.document.documentElement.style.margin = '0px';
		Browser.document.documentElement.style.padding = '0px';
		Browser.document.documentElement.style.height = '100%';
		Browser.document.documentElement.style.overflow = 'hidden';

		updateCanvasSize(Browser.window.innerWidth, Browser.window.innerHeight);

		canvasUsingClientSize = true;
	}

	static function onMouseDownCanvasFullscreen(button:Int, x:Int, y:Int):Void
	{
		if (!kha.SystemImpl.isFullscreen())		
			kha.SystemImpl.requestFullscreen();		
	}
	
	static function onFullscreenChange():Void
	{		
		if (canvasUsingClientSize || Browser.document.fullscreenEnabled)
			updateGameSize(Browser.window.innerWidth, Browser.window.innerHeight);
		else
			updateGameSize(canvasSizeBeforeFullscreen.x, canvasSizeBeforeFullscreen.y);		

		updateCanvasSize(Plm.windowWidth, Plm.windowHeight);		
	}

	@:allow(plume.tools.WebMobile)
	static function updateGameSize(windowWidth:Int, windowHeight:Int):Void
	{
		Plm.windowWidth = windowWidth;
		Plm.windowHeight = windowHeight;

		if (instance.backbuffer == null)
		{
			Plm.gameWidth = Plm.windowWidth;
			Plm.gameHeight = Plm.windowHeight;
		}
		
		Plm.gameScale = Plm.windowWidth / Plm.gameWidth;

		if (Plm.state != null)
			Plm.state.windowSizeUpdated();
	}

	@:allow(plume.tools.WebMobile)
	static function updateCanvasSize(canvasWidth:Int, canvasHeight:Int):Void
	{
		//var khanvas:js.html.CanvasElement = kha.SystemImpl.khanvas != null ? 
		//	kha.SystemImpl.khanvas : cast js.Browser.document.getElementById('khanvas');
		var khanvas = SystemImpl.khanvas;

		khanvas.width = canvasWidth;
		khanvas.height = canvasHeight;
		khanvas.style.width = Std.string(canvasWidth);
		khanvas.style.height = Std.string(canvasHeight);

		SystemImpl.gl.viewport(0, 0, canvasWidth, canvasHeight);
	}
	#end	
}