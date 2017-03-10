package plume;

import kha.math.Vector2;
import kha.graphics2.Graphics;

class State
{
	public var camera:Vector2;

	public function new():Void
	{
		camera = new Vector2();
	}

	public function init():Void {}
	public function update():Void {}
	public function render(g:Graphics):Void {}
}