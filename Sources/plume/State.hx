package plume;

import kha.graphics2.Graphics;

@:allow(plume.Engine)
class State
{	
	public var cameras:Array<Camera>;

	public var worldWidth:Int;
    public var worldHeight:Int;

	var isClippingCamera:Bool;	

	public function new():Void 
	{
		cameras = new Array<Camera>();
		cameras.push(new Camera(Plm.gameWidth, Plm.gameHeight));

		worldWidth = Plm.gameWidth;
        worldHeight = Plm.gameHeight;

		isClippingCamera = false;
	}

	public function init():Void {}
	public function update():Void {}
	public function windowSizeUpdated():Void {}
	public function render(g:Graphics):Void {}
	public function destroy():Void {}

	public function setWorldSize(width:Int, height:Int):Void
    {
        this.worldWidth = width;
        this.worldHeight = height;        
    }

	function addCamera(camera:Camera):Int
	{
		cameras.push(camera);

		return cameras.length - 1;
	}

	inline function removeCamera(cameraIndex:Int):Void
	{
		cameras.splice(cameraIndex, 1);
	}

	@:noCompletion
	function updateCameras():Void
	{
		for (camera in cameras)
			camera.update();
	}

	public inline function beginCamera(g:Graphics, cameraIndex:Int, clip:Bool):Void
	{
		g.pushTranslation(-cameras[cameraIndex].x + cameras[cameraIndex].offsetX, 
			-cameras[cameraIndex].y + cameras[cameraIndex].offsetY);

		if (clip)
		{
			g.scissor(Std.int(cameras[cameraIndex].offsetX), Std.int(cameras[cameraIndex].offsetY), 
				cameras[cameraIndex].width, cameras[cameraIndex].height);
			isClippingCamera = true;
		}
	}

	public inline function endCamera(g:Graphics):Void
	{
		g.popTransformation();

		if (isClippingCamera)
		{
			g.disableScissor();
			isClippingCamera = false;
		}
	}		
}