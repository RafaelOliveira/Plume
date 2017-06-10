package plume.tools;

import kha.Blob;
import format.tmx.Data.TmxMap;
import format.tmx.Reader;
import format.tmx.Data.TmxObject;
import format.tmx.Data.TmxObjectType;
import format.tmx.Tools;

#if differ
import differ.shapes.Shape;
import differ.shapes.Polygon as DifferPolygon;
import differ.math.Vector as DifferVector;
#end

class FormatTmx
{	
	public var tmxMap:TmxMap;
	public var tiles:Map<String, Array<Array<Int>>>;
	public var objects:Map<String, Array<TmxObject>>;

	public function new(tmxFile:Blob, fixObjectPos:Bool = false):Void
	{
		var reader = new Reader(Xml.parse(tmxFile.toString()));
		tmxMap = reader.read();

		// Only works with tile-objects. With rectangles
		// the positions became wrong (they dont't need to be fixed).
		if (fixObjectPos)
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

	public function getTileGidsFromTileset(tilesetName:String):Map<Int, String>
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

	#if differ
	public function getCollisionShapes(layerName:String):Array<Shape>
	{
		var collShapes = new Array<Shape>();
		var objectGroup = objects.get(layerName);

		for (object in objectGroup)
		{
			switch(object.objectType)
			{
				case TmxObjectType.Rectangle:
					collShapes.push(DifferPolygon.rectangle(object.x, object.y, object.width, object.height, false));

				case Polygon(points):
					var vertices = new Array<DifferVector>();

					for (p in points)
						vertices.push(new DifferVector(p.x, p.y));

					collShapes.push(new DifferPolygon(object.x, object.y, vertices));

				default:
					continue;
			}
		}

		return collShapes;
	}
	#end

	public function destroy():Void
	{
		for (key in tiles.keys())
			tiles.remove(key);
		
		for (key in objects.keys())
			objects.remove(key);
		
		tiles = null;
		objects = null;
		tmxMap = null;
	}
}