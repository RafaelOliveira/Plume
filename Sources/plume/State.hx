package plume;

import kha.graphics2.Graphics;

@:allow(plume.Engine)
@:allow(plume.Camera)
class State
{	
	/** The default camera **/
	public var camera(get, null):Camera;

	var cameras:Array<Camera>;

	public var worldWidth:Int;
    public var worldHeight:Int;	

	public function new():Void 
	{
		cameras = new Array<Camera>();
		cameras.push(new Camera(Plm.gameWidth, Plm.gameHeight));

		worldWidth = Plm.gameWidth;
        worldHeight = Plm.gameHeight;		
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

	public function addCamera(camera:Camera):Int
	{
		cameras.push(camera);

		return cameras.length - 1;
	}

	inline public function removeCamera(cameraIndex:Int):Void
	{
		cameras.splice(cameraIndex, 1);
	}

	inline public function getCamera(cameraIndex:Int):Camera
	{
		return cameras[cameraIndex];
	}

	@:noCompletion
	function updateCameras():Void
	{
		for (camera in cameras)
			camera.update();
	}	

	inline function get_camera():Camera
	{
		return cameras[0];
	}
}