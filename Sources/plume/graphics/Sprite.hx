package plume.graphics;

import kha.Image;
import kha.graphics2.Graphics;
import kha.math.Vector2i;
import plume.math.Vector2b;
import plume.atlas.Atlas;
import plume.atlas.Region;
import plume.atlas.Atlas.ImageType;

class Sprite
{	
	/**
	 * The region inside the image that is rendered
	 */
	public var region:Region;
	/**
	 * The width of the region scaled with scaleX
	 */
	public var width(default, null):Int;
	/**
	 * The height of the region scaled with scaleY
	 */
	public var height(default, null):Int;
	/**
	 * A scale in x to render the region
	 */
	public var scaleX(default, set):Float;	
	/**
	 * A scale in y to render the region
	 */
	public var scaleY(default, set):Float;
	/**
	 * If the sprite should be rendered flipped
	 */
	public var flip:Vector2b;	
	
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
		
		scaleX = 1;
		scaleY = 1;
		
		flip = new Vector2b();
	}
	
	public function render(g:Graphics, x:Float, y:Float):Void 
	{
		g.drawScaledSubImage(region.image, region.sx, region.sy, region.width, region.height,
			x + (flip.x ? width : 0),
			y + (flip.y ? height : 0), 
			flip.x ? -width : width, flip.y ? -height : height);
	}
	
	public function setScale(value:Float):Void
	{
		scaleX = value;
		scaleY = value;
	}

	public function applyScale():Void
	{
		width = Std.int(region.width * scaleX);
		height = Std.int(region.height * scaleY);
	}
	
	public function setFlip(flipX:Bool, flipY:Bool):Void
	{
		flip.x = flipX;
		flip.y = flipY;
	}	
		
	function set_scaleX(value:Float):Float
	{		
		width = Std.int(region.width * value);
		
		return scaleX = value;
	}	
	
	function set_scaleY(value:Float):Float
	{
		height = Std.int(region.height * value);
		
		return scaleY = value;
	}
}