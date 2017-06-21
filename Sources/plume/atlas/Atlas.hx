package plume.atlas;

import haxe.xml.Fast;
import haxe.Json;
import kha.Image;
import kha.Blob;

@:structInit
class TexturePackerFrame {
	public var x:Int;
	public var y:Int;
	public var w:Int;
	public var h:Int;
}

@:structInit
class TexturePackerItem {
	public var filename:String;
	public var frame:TexturePackerFrame;
}

@:structInit
class TexturePackerData {
	public var frames:Array<TexturePackerItem>;
}

enum ThreeOptions<F, S, T>
{
	First( v:F );
	Second( v:S );
	Third( v:T );
}

/**
 * Abstract representing either a Image, a Region, or the name of a Region.
 * Conversion is automatic, no need to use this.
 */
abstract ImageType(ThreeOptions<Image, Region, String>)
{
	@:dox(hide) public inline function new(e:ThreeOptions<Image, Region, String>) this = e;
	@:dox(hide) public var type(get, never):ThreeOptions<Image, Region, String>;
	@:to inline function get_type() return this;
	@:from static function fromFirst(v:Image) return new ImageType(First(v));
	@:from static function fromSecond(v:Region) return new ImageType(Second(v));
	@:from static function fromThird(v:String) return new ImageType(Third(v));
}

class Atlas
{
	static var cache:Map<String, Region>;

	public static function exist():Bool
	{
		return (cache != null);
	}

	public static function getRegion(regionName:String):Region
	{
		var region = cache.get(regionName);
		if (region != null)
			return region;
		else
		{
			trace('(getRegion) region "$regionName" not found');
			return null;
		}
	}

	public static function getRegions(regionNames:Array<String>):Array<Region>
	{
		var region:Region;
		var listRegions = new Array<Region>();

		for (name in regionNames)
		{
			region = cache.get(name);
			if (region != null)
				listRegions.push(region);
			else
				trace('(getRegions) region "$name" not found');
		}

		return listRegions;
	}

	public static function getRegionsByIndex(regionName:String, startIndex:Int, endIndex:Int):Array<Region>
	{
		var listRegionNames = new Array<String>();
		endIndex++;

		for (i in startIndex...endIndex)
			listRegionNames.push('$regionName-$i');

		return getRegions(listRegionNames);
	}

	public static function createRegionList(source:ImageType, regionWidth:Int, regionHeight:Int):Array<Region>
	{
		var reg:Region = null;

		switch (source.type)
		{
			case First(image):
				reg = new Region(image, 0, 0, image.width, image.height);

			case Second(region):
				reg = region;

			case Third(regionName):
				reg = Atlas.getRegion(regionName);
		}

		var regions = new Array<Region>();
        var cols = Std.int(reg.width / regionWidth);
        var rows = Std.int(reg.height / regionHeight);

        for (r in 0...rows)
        {
            for (c in 0...cols)
                regions.push(new Region(reg.image, reg.sx + (c * regionWidth), reg.sy + (r * regionHeight), regionWidth, regionHeight));
        }

        return regions;
	}

	public static function createRegion(source:ImageType, sx:Float, sy:Float, w:Int, h:Int):Region
	{
		var regionSource:Region = null;

		switch (source.type)
		{
			case First(image):
				regionSource = new Region(image, 0, 0, image.width, image.height);

			case Second(region):
				regionSource = region;

			case Third(regionName):
				regionSource = Atlas.getRegion(regionName);
		}

		return new Region(regionSource.image, regionSource.sx + sx, regionSource.sy + sy, w, h);
	}

	public static function saveRegion(region:Region, name:String):Void
	{
		if (cache == null)
			cache = new Map<String, Region>();

		cache.set('$name', region);
	}

	public static function saveRegionList(regions:Array<Region>, baseName:String):Void
	{
		if (cache == null)
			cache = new Map<String, Region>();

		for (i in 1...(regions.length + 1))
			cache.set('$baseName-$i', regions[i - 1]);
	}

	public static function removeRegion(regionName):Void
	{
		cache.remove(regionName);
	}

	public static function loadAtlasShoebox(image:Image, xml:Blob):Void
	{
		if (cache == null)
			cache = new Map<String, Region>();

		var blobString:String = xml.toString();
		var fullXml:Xml = Xml.parse(blobString);
		var firstNode:Xml = fullXml.firstElement(); // <TextureAtlas>
		var data = new Fast(firstNode);

		for (st in data.nodes.SubTexture)
		{
			var region = new Region(image, Std.parseInt(st.att.x), Std.parseInt(st.att.y), Std.parseInt(st.att.width), Std.parseInt(st.att.height));
			var name = StringTools.replace(st.att.name, '.png', '');
			name = StringTools.replace(name, '.jpg', '');
			cache.set(name, region);
		}
	}

	public static function loadAtlasTexturePacker(image:Image, xml:Blob):Void
	{
		if (cache == null)
			cache = new Map<String, Region>();

		var data:TexturePackerData = Json.parse(xml.toString());

		for (item in data.frames)
		{
			var region = new Region(image, item.frame.x, item.frame.y, item.frame.w, item.frame.h);
			cache.set(item.filename, region);
		}
	}

	public static function loadAtlasLibGdx(image:Image, data:Blob):Void
	{
		if (cache == null)
			cache = new Map<String, Region>();

		var dataString = StringTools.trim(data.toString());
		var lines = dataString.split('\n');
		var totalItems = Std.int((lines.length - 5) / 7);

		for (i in 0...totalItems)
		{
			var position = lines[5 + (i * 7) + 2].substr(6).split(', ');
			var size = lines[5 + (i * 7) + 3].substr(8).split(', ');

			var region = new Region(image, Std.parseFloat(position[0]), Std.parseFloat(position[1]), Std.parseInt(size[0]), Std.parseInt(size[1]));
			cache.set(lines[5 + (i * 7)], region);
		}
	}

	public static function loadSimpleAtlas(image:Image, data:Blob):Void
	{
		if (cache == null)
			cache = new Map<String, Region>();

		var dataString = StringTools.trim(data.toString());
		var lines = dataString.split('\n');

		for (line in lines)
		{
			var dataItem = line.split(';');
			var region = new Region(image, Std.parseInt(dataItem[1]), Std.parseInt(dataItem[2]), Std.parseInt(dataItem[3]), Std.parseInt(dataItem[4]));
			cache.set(dataItem[0], region);
		}
	}
}