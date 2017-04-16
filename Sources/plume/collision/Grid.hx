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

	public function loadFromTilemap(tilemap:Tilemap, solidTiles:Array<Int>):Void
	{
		data = new Array<Array<Tile>>();

		for (y in 0...tilemap.data.length)
		{
			data.push(new Array<Tile>());

			for (x in 0...tilemap.data[y].length)
			{
				if (solidTiles.indexOf(tilemap.data[y][x]) > -1)
					data[y].push(new Tile(true));
				else
					data[y].push(new Tile(false));
			}
		}

		rows = data.length;
		columns = data[0].length;
		rect = new Rectangle(0, 0, columns * tileWidth, rows * tileHeight);
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

	/**
	 * Shoots a ray from the start point to the end point.
	 * If/when it passes through a tile, it stores that point and returns false.
	 * 
	 * @param	Start		The world coordinates of the start of the ray.
	 * @param	End			The world coordinates of the end of the ray.
	 * @param	Result		An optional point containing the first wall impact if there was one. Null otherwise.
	 * @param	Resolution	Defaults to 1, meaning check every tile or so.  Higher means more checks!
	 * @return	Returns true if the ray made it from Start to End without hitting anything. Returns false and fills Result if a tile was hit.
	 */
	public function ray(start:Vector2, end:Vector2, ?result:Vector2, resolution:Float = 1):Bool
	{
        var tWidth = tileWidth;
        var tHeight = tileHeight;

		var width = columns * tileWidth;
		var height = rows * tileHeight;
        
		var step:Float = tWidth;
		
		if (tHeight < tWidth)
			step = tHeight;
		
		step /= resolution;
		var deltaX:Float = end.x - start.x;
		var deltaY:Float = end.y - start.y;
		var distance:Float = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
		var steps:Int = Math.ceil(distance / step);
		var stepX:Float = deltaX / steps;
		var stepY:Float = deltaY / steps;
		var curX:Float = start.x - stepX;
		var curY:Float = start.y - stepY;
		var tileX:Int;
		var tileY:Int;
		var i:Int = 0;
                		
		while (i < steps)
		{
			curX += stepX;
			curY += stepY;
			
			if ((curX < 0) || (curX > width) || (curY < 0) || (curY > height))
			{
				i++;
				continue;
			}
			
			tileX = Math.floor(curX / tWidth);
			tileY = Math.floor(curY / tHeight);
			
			if (data[tileY][tileX].solid)
			{
				// Some basic helper stuff
				tileX *= Std.int(tWidth);
				tileY *= Std.int(tHeight);
				var rx:Float = 0;
				var ry:Float = 0;
				var q:Float;
				var lx:Float = curX - stepX;
				var ly:Float = curY - stepY;
				
				// Figure out if it crosses the X boundary
				q = tileX;
				
				if (deltaX < 0)				
					q += tWidth;				
				
				rx = q;
				ry = ly + stepY * ((q - lx) / stepX);
				
				if ((ry >= tileY) && (ry <= tileY + tHeight))
				{
					if (result == null)					
						result = new Vector2();					
					
					result.x = rx; 
                    result.y = ry;
                    
					return false;
				}
				
				// Else, figure out if it crosses the Y boundary
				q = tileY;
				
				if (deltaY < 0)				
					q += tHeight;				
				
				rx = lx + stepX * ((q - ly) / stepY);
				ry = q;
				
				if ((rx >= tileX) && (rx <= tileX + tWidth))
				{
					if (result == null)					
						result = new Vector2();					
					
					result.x = rx;
                    result.y = ry;
                    
					return false;
				}
				
				return true;
			}
			i++;
		}
		
		return true;
	}

	/**
	* Saves the grid data to a string.
	* @param	columnSep	The string that separates each tile value on a row, default is ",".
	* @param	rowSep		The string that separates each row of tiles, default is "\n".
	*
	* @return The string version of the grid.
	*/
	public function saveToString(columnSep:String = ',', rowSep:String = '\n',
		solid:String = 'true', empty:String = 'false'): String
	{
		var s:String = '',
			x:Int, y:Int;

		for (y in 0...rows)
		{
			for (x in 0...columns)
			{
				s += Std.string(getTile(x, y) ? solid : empty);

				if (x != columns - 1) 
					s += columnSep;
			}

			if (y != rows - 1) 
				s += rowSep;
		}

		return s;
	}

	public function printToConsole(showBlankLines:Bool = false):Void
	{
		var line:String;

		for (y in 0...rows)
		{
			line = (y % 2 == 0 ? '[' : ']');

			for (x in 0...columns)
			{
				if (data[y][x].solid)
					line += '#';
				else
					line += ' ';
			}

			line = StringTools.rtrim(line);

			if (line.length > 1 || (line.length == 1 && showBlankLines))
			{
				#if js
				js.Browser.console.log(line);
				#else
				trace(line); // TODO: put the right command to print in the console in cpp
				#end
			}
		}
	}
}