package plume.tools;

import kha.Blob;
import format.tmx.Data.TmxMap;
import format.tmx.Reader;
import format.tmx.Data.TmxObject;
import format.tmx.Tools;

class FormatTmx
{	
	public var tmxMap:TmxMap;
	public var tiles:Map<String, Array<Array<Int>>>;
	public var objects:Map<String, Array<TmxObject>>;

	public function new(tmxFile:Blob):Void
	{
		var reader = new Reader(Xml.parse(tmxFile.toString()));
		tmxMap = reader.read();

		Tools.fixObjectPlacement(tmxMap);

		for (layer in tmxMap.layers)
		{
			switch (layer)
			{
				case TileLayer(layer):
					if (tiles == null)
						tiles = new Map<String, Array<Array<Int>>>();
					
					var data = new Array<Array<Int>>();
					var i = 0;

					for (y in 0...layer.height)
					{
						data.push(new Array<Int>());

						for (x in 0...layer.width)
						{
							data[y].push(layer.data.tiles[i].gid - 1);
							i++;
						}
					}

					tiles.set(layer.name, data);
					
				case ObjectGroup(group):
					if (objects == null)
						objects = new Map<String, Array<TmxObject>>();
					
					objects.set(group.name, group.objects);

				default: continue;
			}
		}
	}

	public function getTilesFromTileset(tilesetName:String):Map<Int, String>
	{
		var tiles = new Map<Int, String>();

		for (tmxTileset in tmxMap.tilesets)
		{
			if (tmxTileset.name == tilesetName)
			{
				var gid = tmxTileset.firstGID;
				
				for (tile in tmxTileset.tiles)
				{
					// get the name of the images without the extension					
					var name = tile.image.source;					
					name = StringTools.replace(name, '.png', '');

					tiles.set(gid + tile.id, name);
				}
			}
		}

		return tiles;
	}
}