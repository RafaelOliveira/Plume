package plume.graphics;

import kha.graphics2.Graphics;
import plume.atlas.Region;
import plume.atlas.Atlas;
import plume.atlas.Atlas.ImageType;

/**
 * This class render a graphic repeatedly inside an area
 * but will not cut the graphic if is rendering outside the limits
**/
class TileArea
{
	public var region:Region;
	var sx:Float;

	public function new(source:ImageType):Void
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
	}

	public function render(g:Graphics, x:Float, y:Float, width:Int, height:Int):Void
	{
		sx = x;

		while(y < height)
		{
			while (x < width)
			{
				g.drawScaledSubImage(region.image, region.sx, region.sy,
									 region.width, region.height, x, y, region.width, region.height);
				x += region.width;
			}

			y += region.height;
			x = sx;
		}
	}
}