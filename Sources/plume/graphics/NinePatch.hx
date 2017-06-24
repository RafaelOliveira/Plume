package plume.graphics;

import kha.Image;
import kha.graphics2.Graphics;
import kha.math.Vector2i;
import plume.atlas.Atlas;
import plume.atlas.Region;
import plume.atlas.Atlas.ImageType;

class NinePatch
{	
	/**
	 * The region inside the image that is rendered
	 */
	public var region:Region;	
	
	var leftBorder:Int;
	var rightBorder:Int;
	var topBorder:Int;
	var bottomBorder:Int;
	
	public var width(default, set):Int;
	public var height(default, set):Int;

	var innerWidth:Int;
	var innerHeight:Int;

	public function new (source:ImageType, leftBorder:Int, rightBorder:Int, topBorder:Int, bottomBorder:Int, width:Int, height:Int):Void
	{		
		switch (source.type)
		{
			case First(image):
				this.region = Region.createFromImage(image);
			
			case Second(region):
				this.region = region;

			case Third(regionName):
				this.region = Atlas.getRegion(regionName);
		}		

		this.leftBorder = leftBorder;
		this.rightBorder = rightBorder;
		this.topBorder = topBorder;
		this.bottomBorder = bottomBorder;
		
		this.width = width;
		this.height = height;				
	}	

	public function render(g:Graphics, x:Float, y:Float):Void
	{		
		if (leftBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx, region.sy + topBorder,	// sxy
				leftBorder, region.height - topBorder - bottomBorder,				// swh
				x, y + topBorder,													// xy
				leftBorder, innerHeight);											// wh
		}

		if (rightBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx + region.width - rightBorder, region.sy + topBorder,
				rightBorder, region.height - topBorder - bottomBorder,
				x + leftBorder + innerWidth, y + topBorder,
				rightBorder, innerHeight);
		}

		if (topBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx + leftBorder, region.sy,
				region.width - leftBorder - rightBorder, topBorder,
				x + leftBorder, y,
				innerWidth, topBorder);
		}

		if (bottomBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx + leftBorder, region.sy + region.height - bottomBorder,
				region.width - leftBorder - rightBorder, bottomBorder,
				x + leftBorder, y + topBorder + innerHeight,
				innerWidth, bottomBorder);
		}

		if (leftBorder > 0 && topBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx, region.sy, 
				leftBorder, topBorder,
				x, y, 
				leftBorder, topBorder);
		}

		if (rightBorder > 0 && topBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx + region.width - rightBorder, region.sy, 
				rightBorder, topBorder,
				x + leftBorder + innerWidth, y,
				rightBorder, topBorder);
		}

		if (leftBorder > 0 && bottomBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx, region.sy + region.height - bottomBorder,
				leftBorder, bottomBorder,
				x, y + topBorder + innerHeight,
				leftBorder, bottomBorder);
		}

		if (rightBorder > 0 && bottomBorder > 0)
		{
			g.drawScaledSubImage(region.image, region.sx + region.width - rightBorder, region.sy + region.height - bottomBorder,
				rightBorder, bottomBorder,
				x + leftBorder + innerWidth, y + topBorder + innerHeight,
				rightBorder, bottomBorder);
		}

		g.drawScaledSubImage(region.image, region.sx + leftBorder, region.sy + topBorder,
			region.width - leftBorder - rightBorder, region.height - topBorder - bottomBorder,
			x + leftBorder, y + topBorder,
			innerWidth, innerHeight);		
	}

	inline function set_width(value:Int):Int
	{
		innerWidth = value - leftBorder - rightBorder;

		if (innerWidth < 0)
			innerWidth = 0;

		return (width = value);
	}

	inline function set_height(value:Int):Int
	{
		innerHeight = value - topBorder - bottomBorder;

		if (innerHeight < 0)
			innerHeight = 0;

		return (height = value);
	}	
}