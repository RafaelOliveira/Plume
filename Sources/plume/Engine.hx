package plume;

import kha.System;
import kha.Framebuffer;
import kha.Scheduler;
import kha.Scaler;
import kha.Assets;
import kha.Image;
import kha.graphics2.ImageScaleQuality;
import kha.WindowOptions.Mode;
import kha.WindowOptions.Position;
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
}

class Engine
{
	static var callback:Void->Void;
	static var backbuffer:Image;
	static var highQualityScale:Bool;
	static var inputs:Array<Manager>;

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
		System.init({ title: options.title, width: options.width, height: options.height }, function () {
			Assets.loadEverything(assetsLoaded);
		});
	}

	inline static function initFullscreen(options:EngineOptions)
	{
		System.initEx(options.title,
			[{ x: Position.Fixed(0), y: Position.Fixed(0), width: options.width, height: options.height, mode: Mode.Fullscreen }],
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
		if (Plm.state != null)
		{
			Plm.state.update();

			for (input in inputs)
				input.update();
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