package plume.atlas;

import kha.graphics2.Graphics;
import kha.Image;

/**
 *	Represents a region inside a image
 */
class Region
{
	public var image:Image;

	/** The x position inside the image */
	public var sx:Float;

	/** The y position inside the image */
	public var sy:Float;

	/** Width of the region */
	public var width:Int;

	/** Height of the region */
	public var height:Int;	

	public function new(image:Image, sx:Float, sy:Float, width:Int, height:Int)
	{
		this.image = image;
		this.sx = sx;
		this.sy = sy;
		this.width = width;
		this.height = height;
	}
	 
	inline public function render(g:Graphics, x:Float, y:Float):Void 
	{
		g.drawScaledSubImage(image, sx, sy, width, height, x, y, width, height);
	}		

	public static function createFromImage(image:Image):Region
	{
		return new Region(image, 0, 0, image.width, image.height);
	}

	inline public static function get(regionName:String):Region
	{
		return Atlas.getRegion(regionName);
	}	
}