package plume;

import kha.System;
import kha.Display;
import kha.Framebuffer;
import kha.Scheduler;
import kha.Scaler;
import kha.Assets;
import kha.Image;
import kha.graphics2.ImageScaleQuality;
import kha.WindowOptions.Mode;
import kha.WindowOptions.Position;
import kha.math.Vector2i;
import plume.input.Manager;

@:structInit
class EngineOptions
{
	@:optional public var title:String;
	@:optional public var width:Null<Int>;
	@:optional public var height:Null<Int>;
	@:optional public var bbWidth:Null<Int>;
	@:optional public var bbHeight:Null<Int>;
	@:optional public var highQualityScale:Null<Bool>;
	@:optional public var fullscreen:Null<Bool>;
	@:optional public var samplesPerPixel:Null<Int>;
}

@:allow(plume.Plm)
class Engine
{
	static var callback:Void->Void;
	static var backbuffer:Image;
	static var highQualityScale:Bool;
	static var inputs:Array<Manager>;

	static var currTime:Float = 0;
	static var prevTime:Float = 0;

	#if js
	static var canvasUsingClientSize:Bool = false;
	#end

	public static function init(options:EngineOptions, callback:Void->Void):Void
	{
		if (options.title == null)
			options.title = 'Project';

		if (options.width == null)
			options.width = 800;

		if (options.height == null)
			options.width = 600;

		highQualityScale = options.highQualityScale != null ? options.highQualityScale : false;

		Engine.callback = callback;

		inputs = new Array<Manager>();

		if (options.bbWidth != null && options.bbHeight != null)
			backbuffer = Image.createRenderTarget(options.bbWidth, options.bbHeight);

		currTime = Scheduler.time();

		#if js
		initWindowed(options);
		#else
		if (!options.fullscreen)
			initWindowed(options);
		else
			initFullscreen(options);
		#end
	}

	inline static function initWindowed(options:EngineOptions)
	{
		System.init({ title: options.title, width: options.width, height: options.height, samplesPerPixel: options.samplesPerPixel }, function () {
			Assets.loadEverything(assetsLoaded);
		});
	}

	inline static function initFullscreen(options:EngineOptions)
	{
		System.initEx(options.title,
			[{ x: Position.Fixed(0), y: Position.Fixed(0), width: options.width, height: options.height, mode: Mode.Fullscreen, 
			rendererOptions: { samplesPerPixel: options.samplesPerPixel } }], 
			function(_) {}, function() {
				Assets.loadEverything(assetsLoaded);
		});
	}

	public static function enableInput(options:Int):Void
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
		kha.input.Mouse.get().notify(onMouseDownFullscreen, null, null, null, null);
		#else
		kha.SystemImpl.requestFullscreen();
		#end

		kha.SystemImpl.notifyOfFullscreenChange(Plm.updateWindowSize, null);
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

	static function onMouseDownFullscreen(button:Int, x:Int, y:Int):Void
	{
		if (!kha.SystemImpl.isFullscreen())		
			kha.SystemImpl.requestFullscreen();		
	}
	#end

	static function assetsLoaded():Void
	{
		if (backbuffer != null)
		{
			Plm.init(true, backbuffer.width, backbuffer.height);
			System.notifyOnRender(renderWithBackbuffer);
		}
		else
		{
			Plm.init(false, 0, 0);
			System.notifyOnRender(renderWithFramebuffer);
		}

		Scheduler.addTimeTask(update, 0, 1 / 60);

		callback();
		callback = null;
	}

	static function update():Void
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

	static function renderWithFramebuffer(framebuffer:Framebuffer):Void
	{
		if (Plm.state != null)
		{
			framebuffer.g2.begin(false);
			Plm.state.render(framebuffer.g2);
			framebuffer.g2.end();
		}
	}

	static function renderWithBackbuffer(framebuffer:Framebuffer):Void
	{
		if (Plm.state != null)
		{
			backbuffer.g2.begin(false);
			Plm.state.render(backbuffer.g2);
			backbuffer.g2.end();

			framebuffer.g2.begin();

			if (highQualityScale)
				framebuffer.g2.imageScaleQuality = ImageScaleQuality.High;

			Scaler.scale(backbuffer, framebuffer, System.screenRotation);
			framebuffer.g2.end();
		}
	}
}