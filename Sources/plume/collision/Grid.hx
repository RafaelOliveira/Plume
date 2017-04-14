package plume.collision;

import kha.math.Vector2;
import plume.math.Rectangle;
import plume.graphics.Tilemap;

class Grid extends Body
{
	public var tileWidth(default, null):Int;
	public var tileHeight(default, null):Int;

	public var columns(default, null):Int;
	public var rows(default, null):Int;

	public var data(default, null):Array<Array<Tile>>;

	public function new(pos:Vector2, tileWidth:Int, tileHeight:Int):Void
	{
		super(pos, null);

		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;

		type = Body.GRID;
	}

	public function setTile(x:Int, y:Int, solid:Bool = true):Void
	{
		if (!checkValidTile(x, y)) 
			return;

		data[y][x].solid = solid;
	}

	public function getTile(x:Int, y:Int):Bool
	{
		if (!checkValidTile(x, y))
			return false;

		return data[y][x].solid;
	}

	inline public function clearTile(x:Int, y:Int):Void
	{
		setTile(x, y, false);
	}

	inline function checkValidTile(x:Int, y:Int):Bool
	{
		// check that tile is valid
		if (x < 0 || x > columns - 1 || y < 0 || y > rows - 1)		
			return false;		
		else		
			return true;
	}

	/**
	 * Sets the value of a rectangle region of tiles.
	 * @param	column		First column.
	 * @param	row			First row.
	 * @param	width		Columns to fill.
	 * @param	height		Rows to fill.
	 * @param	solid		Value to fill.
	 */
	public function setArea(x:Int, y:Int, width:Int = 1, height:Int = 1, solid:Bool = true):Void
	{
		for (yy in y...(y + height))
		{
			for (xx in x...(x + width))
				setTile(xx, yy, solid);			
		}
	}

	/**
	 * Makes the rectangular region of tiles non-solid.
	 * @param	column		First column.
	 * @param	row			First row.
	 * @param	width		Columns to fill.
	 * @param	height		Rows to fill.
	 */
	public inline function clearArea(x:Int, y:Int, width:Int = 1, height:Int = 1):Void
	{
		setArea(x, y, width, height, false);
	}

	public function setColRect(x:Int, y:Int, rect:Rectangle):Void
	{
		if (!checkValidTile(x, y))
			return;

		data[y][x].rect = rect;
		data[y][x].solid = rect != null ? true : false;		
	}

	inline public function clearColRect(x:Int, y:Int):Void
	{
		setColRect(x, y, null);
	}

	public function loadEmpty(columns:Int, rows:Int):Void
	{
		data = new Array<Array<Tile>>();

		this.rows = rows;
		this.columns = columns;		
		
		for (y in 0...rows)
		{
			data.push(new Array<Tile>());
			
			for (x in 0...columns)
				data[y].push(new Tile(false));
		}
	}

	/**
	* Loads the grid data from a string.
	* @param	str			The string data, which is a set of tile values (0 or 1) separated by the columnSep and rowSep strings.
	* @param	columnSep	The string that separates each tile value on a row, default is ",".
	* @param	rowSep		The string that separates each row of tiles, default is "\n".
	*/
	public function loadFromString(str:String, columnSep:String = ',', rowSep:String = '\n'):Void
	{
		var row:Array<String> = str.split(rowSep);
		var rows:Int = row.length;
		var col:Array<String>, cols:Int;

		data = new Array<Array<Tile>>();
			
		for (y in 0...rows)
		{
			data.push(new Array<Tile>());

			if (row[y] == '') 
				continue;			

			col = row[y].split(columnSep);
			cols = col.length;

			for (x in 0...cols)
			{
				if (col[x] == '') 
					data[y].push(new Tile(false));
				else
					data[y].push(new Tile(Std.parseInt(col[x]) > 0));
			}
		}

		rows = data.length;
		columns = data[0].length;
		rect = new Rectangle(0, 0, columns * tileWidth, rows * tileHeight);
	}

	/**
	* Loads the grid data from an array.
	* @param	array	The array data, which is a set of tile values (0 or 1)
	*/
	public function loadFrom2DArray(array:Array<Array<Int>>)
	{
		data = new Array<Array<Tile>>();

		for (y in 0...array.length)
		{
			data.push(new Array<Tile>());

			for (x in 0...array[y].length)
				data[y].push(new Tile(array[y][x] > 0));				
		}

		rows = data.length;
		columns = data[0].length;
		rect = new Rectangle(0, 0, columns * tileWidth, rows * tileHeight);
	}

	public funciton loadFromTilemap(tilemap:Tilemap):Void
	{
		loadFrom2DArray(tilemap.map);
	}

	override public function collideBody(body:Body, x:Float, y:Float):Body
	{
		var tx1 = (x + body.rect.x) - (pos.x + rect.x);
		var ty1 = (y + body.rect.y) - (pos.y + rect.y);

		var x2 = Std.int((tx1 + body.rect.width - 1) / tileWidth) + 1;
		var y2 = Std.int((ty1 + body.rect.height - 1) / tileHeight) + 1;
		var x1 = Std.int(tx1 / tileWidth);
		var y1 = Std.int(ty1 / tileHeight);

		var tile:Tile;

		for (dy in y1...y2)
		{
			for (dx in x1...x2)
			{
				if (checkValidTile(dx, dy))
				{
					tile = data[dy][dx];
					
					if (tile.solid)
					{
						if (tile.rect == null)
							return body;
						else if (body.collideRect(x, y, (dx * tileWidth) + tile.rect.x, (dy * tileHeight) + tile.rect.y, tile.rect.width, tile.rect.height))
							return body;
					}
				}
			}
		}

		return null;
	}
}