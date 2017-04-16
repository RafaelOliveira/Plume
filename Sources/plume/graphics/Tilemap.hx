package plume.graphics;

import kha.Blob;
import kha.math.Vector2i;
import kha.graphics2.Graphics;

class Tilemap
{
	public var tileset:Tileset;

	public var tileWidth(get, null):Int;
	public var tileHeight(get, null):Int;

	public var columns(default, null):Int;
	public var rows(default, null):Int;

	/** Width in pixels **/
	public var width(default, null):Int;

	/** Height in pixels **/
	public var height(default, null):Int;

	public var data:Array<Array<Int>>;

	// temp variables
	var _x:Float;
	var _y:Float;
	var _startCol:Int;
	var _endCol:Int;
	var _startRow:Int;
	var _endRow:Int;

	public function new(tileset:Tileset):Void
	{
		this.tileset = tileset;
	}

	public function setTile(x:Int, y:Int, value:Int):Void
	{	
		if (!checkValidTile(x, y)) 
			return;

		data[y][x] = value;		
	}
	
	public function getTile(x:Int, y:Int):Int
	{
		if (checkValidTile(x, y))
			return data[y][x];
		else
			return -1;
	}

	public function clearTile(x:Int, y:Int):Void
	{
		setTile(x, y, -1);
	}

	inline function checkValidTile(x:Int, y:Int):Bool
	{		
		if (x < 0 || x > columns - 1 || y < 0 || y > rows - 1)		
			return false;		
		else		
			return true;
	}

	public function index(px:Float, py:Float):Vector2i
	{
		var xtile = Std.int(px / tileWidth);
		var ytile = Std.int(py / tileHeight);
		
		return new Vector2i(xtile, ytile);
	}

	public function loadEmpty(columns:Int, rows:Int):Void
	{
		data = new Array<Array<Int>>();

		this.rows = rows;
		this.columns = columns;

		height = rows * tileHeight;
		width = columns * tileWidth;
		
		for (y in 0...rows)
		{
			data.push(new Array<Int>());
			
			for (x in 0...columns)			
				data[y].push(-1);
		}
	}

	/**
	 * Set the tiles from an array.
	 * The array must be of the same size as the Tilemap.
	 *
	 * @param array	The array to load from.
	 */
	public function loadFrom2DArray(array:Array<Array<Int>>):Void
	{
		data = new Array<Array<Int>>();
		
		for (y in 0...array.length)
		{
			data.push(new Array<Int>());
			
			for (x in 0...array[y].length)			
				data[y].push(array[y][x]);			
		}
		
		rows = data.length;
		columns = data[0].length;
		
		height = rows * tileHeight;
		width = columns * tileWidth;
	}

	/**
	* Loads the Tilemap tile index data from a string.
	* The implicit array should not be bigger than the Tilemap.
	* @param str			The string data, which is a set of tile values separated by the columnSep and rowSep strings.
	* @param columnSep		The string that separates each tile value on a row, default is ",".
	* @param rowSep			The string that separates each row of tiles, default is "\n".
	*/
	public function loadFromString(str:String, columnSep:String = ",", rowSep:String = "\n"):Void
	{
		data = new Array<Array<Int>>();
		
		var row:Array<String> = str.split(rowSep);
		var	rows:Int = row.length;
		var	col:Array<String>;
		var cols:Int;		
			
		for (y in 0...rows)
		{
			data.push(new Array<Int>());
			
			if (row[y] == '') 
				continue;
			
			col = row[y].split(columnSep);
			cols = col.length;
			
			for (x in 0...cols)
			{
				if (col[x] != '')		
					data[y].push(Std.parseInt(col[x]));
			}
		}
		
		rows = data.length;
		columns = data[0].length;
		
		height = rows * tileHeight;
		width = columns * tileWidth;
	}

	/**
	 * Load the layers of a pyxel edit file as a list of tilemaps
	 * @param	x	The x position of the tilemaps
	 * @param	y	The y position of the tilemaps
	 * @param	file	the pyxel edit file
	 * @param	tileset	A tileset to draw the tilemaps
	 */
	public static function createFromPyxelEdit(file:Blob, tileset:Tileset):Array<Tilemap>
	{
		var width:Int = 0;
		var height:Int = 0;
		var maps = new Array<Tilemap>();
		var layer:Array<Array<Int>>;
		
		var lines = file.toString().split('\n');
		
		for (i in 0...lines.length)
		{
			var line = StringTools.trim(lines[i]);
			
			if (line.length > 0)
			{
				var tokens = line.split(' ');
				
				switch(tokens[0])
				{
					case 'tileswide':					
						width = Std.parseInt(tokens[1]);
					case 'tileshigh':
						height = Std.parseInt(tokens[1]);
						
					case 'tilewidth':
					case 'tileheight':
						
					case 'layer':
						layer = new Array<Array<Int>>();
						
						for (py in (i + 1)...((i + 1) + height))
						{
							layer.push(new Array<Int>());
							
							var data = lines[py].split(',');
							
							for (px in 0...width)
								layer[layer.length - 1].push(Std.parseInt(data[px]));
						}
						
						var map = new Tilemap(tileset);
						map.loadFrom2DArray(layer);
						maps.push(map);
				}				
			}
		}
		
		return maps;
	}

	public function render(g:Graphics, x:Float, y:Float):Void
	{
		for (my in 0...data.length)
		{
			for (mx in 0...data[my].length)
			{
				if (data[my][mx] != -1)				
					tileset.render(g, data[my][mx], x + (mx * tileWidth), y + (my * tileHeight));
			}
		}
	}

	public function renderInCamera(g:Graphics, x:Float, y:Float, cameraX:Float, cameraY:Float):Void 
	{				
		if 	(((x + width) < cameraX) || (x > (cameraX + Plm.gameWidth)) ||
			((y + height) < cameraY) || (y > (cameraY + Plm.gameHeight)))
				return;		   
		
		_startCol = Math.floor((x > cameraX ? 0 : (cameraX - x)) / tileWidth);
		_endCol = Std.int(((x + width) > (cameraX + Plm.gameWidth) ? (cameraX + Plm.gameWidth - x) : width) / tileWidth);
		_startRow = Math.floor((y > cameraY ? 0 : (cameraY - y)) / tileHeight);
		_endRow = Std.int(((y + height) > (cameraY + Plm.gameHeight) ? (cameraY + Plm.gameHeight - y) : height) / tileHeight);						
		
		if (_endCol < columns)
			_endCol++;
			
		if (_endRow < rows)
			_endRow++;
		
		for (r in _startRow...(_endRow))
		{
			for (c in _startCol...(_endCol))
			{
				var tile = data[r][c];
				if (tile != -1)
				{
					_x = x + (c * tileWidth) - cameraX;
					_y = y + (r * tileHeight) - cameraY;
					
					tileset.render(g, tile, _x, _y);
				}
			}
		}
	}

	inline function get_tileWidth():Int
	{
		return tileset.tileWidth;
	}

	inline function get_tileHeight():Int
	{
		return tileset.tileWidth;
	}	
}