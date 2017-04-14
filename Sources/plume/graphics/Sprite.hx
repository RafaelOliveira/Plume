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
	public var region(default, set):Region;
	/**
	 * A shortcut for the width of the region
	 */
	public var width(get, never):Int;
	/**
	 * A shortcut for the height of the region
	 */
	public var height(get, never):Int;
	/**
	 * A scale in x to render the region
	 */
	public var scaleX(default, set):Float;	
	/**
	 * A scale in y to render the region
	 */
	public var scaleY(default, set):Float;
	/**
	 * The width of the region with the scale applied
	 */
	public var widthScaled(default, null):Int;
	/**
	 * The height of the region with the scale applied
	 */		
	public var heightScaled(default, null):Int;
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
	
	function render(g:Graphics, x:Float, y:Float, cameraX:Float, cameraY:Float):Void 
	{			
		g.drawScaledSubImage(region.image, region.sx, region.sy, region.w, region.h,
			x + (flip.x ? widthScaled : 0) - cameraX,
			y + (flip.y ? heightScaled : 0) - cameraY, 
			flip.x ? -widthScaled : widthScaled, flip.y ? -heightScaled : heightScaled);				
	}    
	
	public function setScale(value:Float):Void
	{
		scaleX = value;
		scaleY = value;
	}
	
	public function setFlip(flipX:Bool, flipY:Bool):Void
	{
		flip.x = flipX;
		flip.y = flipY;
	}
	
	public function set_region(value:Region):Region
	{
		if (value != null)
        {
            widthScaled = Std.int(value.w * scaleX);
		    heightScaled = Std.int(value.h * scaleY);    
        }
        		
		return region = value;
	}

	inline public function get_width():Int
	{
		return region.w;
	}

	inline public function get_height():Int
	{
		return region.h;
	}
		
	public function set_scaleX(value:Float):Float
	{		
		widthScaled = Std.int(region.w * value);
		
		return scaleX = value;
	}	
	
	public function set_scaleY(value:Float):Float
	{
		heightScaled = Std.int(region.h * value);
		
		return scaleY = value;
	}
}