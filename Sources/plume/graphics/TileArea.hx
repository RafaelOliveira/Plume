package plume.graphics;

import kha.graphics2.Graphics;
import plume.atlas.Region;
import plume.atlas.Atlas;
import plume.atlas.Atlas.ImageType;

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
		//width += Std.int(x);
		//height += Std.int(y);

		sx = x;

		while(y < height)
		{
			while (x < width)
			{
				g.drawScaledSubImage(region.image, region.sx, region.sy,
									 region.w, region.h, x, y, region.w, region.h);
				x += region.w;
			}

			y += region.h;
			x = sx;
		}
	}
}