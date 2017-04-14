package plume.graphics;

import kha.graphics2.Graphics;
import plume.Plm;
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
	var _x:Float;
	var _y:Float;
	var _startCol:Int;
	var _endCol:Int;
	var _startRow:Int;
	var _endRow:Int;

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

	inline public function render(g:Graphics, index:Int, x:Float, y:Float):Void
	{
		_x = Std.int(index % widthInTiles);
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

	public function renderMatrixInCamera(g:Graphics, matrix:Array<Array<Int>>, x:Float, y:Float, cameraX:Float, cameraY:Float):Void 
	{
		var widthInPixels = matrix[0].length * tileWidth;
		var heightInPixels = matrix.length * tileHeight;

		if 	(((x + widthInPixels) < cameraX) || (x > (cameraX + Plm.gameWidth)) ||
			((y + heightInPixels) < cameraY) || (y > (cameraY + Plm.gameHeight)))
				return;		   
		
		_startCol = Math.floor((x > cameraX ? 0 : (cameraX - x)) / tileWidth);
		_endCol = Std.int(((x + widthInPixels) > (cameraX + Plm.gameWidth) ? (cameraX + Plm.gameWidth - x) : widthInPixels) / tileWidth);
		_startRow = Math.floor((y > cameraY ? 0 : (cameraY - y)) / tileHeight);
		_endRow = Std.int(((y + heightInPixels) > (cameraY + Plm.gameHeight) ? (cameraY + Plm.gameHeight - y) : heightInPixels) / tileHeight);						
		
		if (_endCol < widthInTiles)
			_endCol++;
			
		if (_endRow < heightInTiles)
			_endRow++;
		
		for (r in _startRow...(_endRow))
		{
			for (c in _startCol...(_endCol))
			{
				var tile = matrix[r][c];
				if (tile != -1)
				{
					_x = x + (c * tileWidth) - cameraX;
					_y = y + (r * tileHeight) - cameraY;
					
					render(g, tile, _x, _y);
				}
			}
		}
	}
}