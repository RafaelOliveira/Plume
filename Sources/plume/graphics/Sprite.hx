package plume.graphics;

import kha.graphics2.Graphics;
import plume.atlas.Atlas;
import plume.atlas.Region;
import plume.atlas.Atlas.ImageType;
import plume.Plm;

class Sprite
{	
	/**
	 * The region inside the image that is rendered
	 */
	public var region:Region;
	/**
	 * The width that will rendered
	 */
	public var width(get, set):Int;
	/**
	 * The height that will be rendered
	 */
	public var height(get, set):Int;
	/**
	 * If the sprite should be rendered flipped in x
	 */
	public var flipX(get, set):Bool;
	/**
	 * If the sprite should be rendered flipped in y
	 */
	public var flipY(get, set):Bool;

	var _fx:Bool;
	var _fy:Bool;

	var _dx:Float;
	var _dy:Float;

	var _dw:Int;
	var _dh:Int;
	
	public function new(source:ImageType):Void
	{		
		switch (source.type)
		{
			case First(image):
				this.region = new Region(image, 0, 0, image.width, image.height);
			
			case Second(region):
				this.region = region;

			case Third(regionName):
				this.region = Atlas.getRegion(regionName); 
		}		
		
		_fx = false;
		_fy = false;

		_dx = 0;
		_dy = 0;

		_dw = region.width;
		_dh = region.height;
	}
	
	public function render(g:Graphics, x:Float, y:Float):Void 
	{
		g.drawScaledSubImage(region.image, region.sx, region.sy, region.width, region.height,
			x + _dx, y + _dy, _dw, _dh);
	}
	
	/**
	 * Sets the width and height based in a scale
	*/
	public function setScale(scaleX:Float, scaleY:Float):Void
	{
		_dw = Std.int(_dw * scaleX);
		_dh = Std.int(_dh * scaleY);
	}

	/**
	 * Sets flipX and flipY together
	*/
	public function setFlip(flipX:Bool, flipY:Bool):Void
	{
		this.flipX = flipX;
		this.flipY = flipY;
	}

	/**
	 * Reset the width to the original width
	*/
	inline public function resetWidth():Void
	{
		width = region.width;		
	}

	/**
	 * Reset the height to the original height
	*/
	inline public function resetHeight():Void
	{
		height = region.height;
	}

	inline function get_width():Int
	{
		return _dw;
	}
	
	inline function set_width(value:Int):Int
	{
		_dw = value;
		flipX = _fx;

		return value;
	}

	inline function get_height():Int
	{
		return _dh;
	}

	inline function set_height(value:Int):Int
	{
		_dh = value;
		flipY = _fy;

		return value;
	}

	inline function get_flipX():Bool
	{
		return _fx;
	}	

	function set_flipX(value:Bool):Bool
	{
		if (value)
		{
			_dx = Plm.iabs(_dw);
			
			if (_dw > 0)
				_dw = -_dw;
		}
		else
		{
			_dx = 0;
			_dw = Plm.iabs(_dw);
		}

		return (_fx = value);
	}

	inline function get_flipY():Bool
	{
		return _fy;
	}

	function set_flipY(value:Bool):Bool
	{
		if (value)
		{
			_dy = Plm.iabs(_dh);
			
			if (_dh > 0)
				_dh = -_dh;
		}
		else
		{
			_dy = 0;
			_dh = Plm.iabs(_dh);
		}

		return (_fy = value);
	}
}