package plume.graphics;

import kha.graphics2.Graphics;
import plume.atlas.Atlas;
import plume.atlas.Region;
import plume.atlas.Atlas.ImageType;

class Tileset
{
	var region:Region;
	public var tileWidth:Int;
	public var tileHeight:Int;
	public var widthInTiles:Int;
	public var heightInTiles:Int;

	// temp variables
	var _x:Int;
	var _y:Int;

	public function new(source:ImageType, tileWidth:Int, tileHeight:Int):Void
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

		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;

		widthInTiles = Std.int(region.w / tileWidth);
		heightInTiles = Std.int(region.h / tileHeight);
	}

	public function render(g:Graphics, index:Int, x:Float, y:Float):Void
	{
		_x = index % widthInTiles;
		_y = Std.int(index / widthInTiles);
		g.drawScaledSubImage(region.image, region.sx + (_x * tileWidth), region.sy + (_y * tileHeight), tileWidth, tileHeight, x, y, tileWidth, tileHeight);
	}

	public function renderMatrix(g:Graphics, matrix:Array<Array<Int>>, x:Float, y:Float):Void
	{
		for (my in 0...matrix.length)
		{
			for (mx in 0...matrix[my].length)
			{
				if (matrix[my][mx] != -1)
				{
					_x = matrix[my][mx] % widthInTiles;
					_y = Std.int(matrix[my][mx] / widthInTiles);

					g.drawScaledSubImage(region.image, region.sx + (_x * tileWidth), region.sy + (_y * tileHeight), tileWidth, tileHeight,
						x + (mx * tileWidth) , y + (my * tileHeight), tileWidth, tileHeight);
				}
			}
		}
	}
}