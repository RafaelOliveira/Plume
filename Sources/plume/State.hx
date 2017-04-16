package plume;

import kha.graphics2.Graphics;

class State
{
	public var camera:Camera;

	public function new():Void
	{
		camera = new Camera();
	}

	public function init():Void {}
	public function update():Void {}
	public function windowSizeUpdated():Void {}

	public function render(g:Graphics):Void {}
}