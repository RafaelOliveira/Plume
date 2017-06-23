package plume.graphics;

import kha.graphics2.Graphics;
import kha.math.Vector2;
import plume.atlas.Atlas;
import plume.atlas.Region;
import plume.atlas.Atlas.ImageType;

class TileSprite
{
    public var region(default, set):Region;

    public var width:Int;
    public var height:Int;

    var tileInfo:Array<Float>;
    var numTiles:Int;

    public var scrollX:Float;    
    public var scrollY:Float;

    var cursor:Vector2;
    
    public function new(source:ImageType, width:Int, height:Int, scrollX:Float = 0, scrollY:Float = 0):Void
    {
        cursor = new Vector2();

        switch (source.type)
		{
			case First(image):
				this.region = new Region(image, 0, 0, image.width, image.height);
			
			case Second(region):
				this.region = region;

			case Third(regionName):
				this.region = Atlas.getRegion(regionName); 
		}

        this.width = width;
        this.height = height;
        
        this.scrollX = scrollX;
        this.scrollY = scrollY;
        
        updateTileInfo();
    }

    public function update():Void
    {
        if (scrollX != 0)
        {
            cursor.x += scrollX;

            if (cursor.x > region.width)
                cursor.x = 0;
            else if (cursor.x < 0)
                cursor.x = region.width;
        }
        
        if (scrollY != 0)
        {
            cursor.y += scrollY;

            if (cursor.y > region.height)
                cursor.y = 0;
            else if (cursor.y < 0)
                cursor.y = region.height;
        }
    }

    function updateTileInfo():Void
    {
        cursor.x = -region.width;
        cursor.y = -region.height;

        tileInfo = new Array<Float>();

        while(cursor.y <= height)
        {
            while(cursor.x <= width)
            {
                tileInfo.push(cursor.x);
                tileInfo.push(cursor.y);

                cursor.x += region.width;
                numTiles++;
            }

            cursor.x = -region.width;
            cursor.y += region.height;
        }

        cursor.x = 0;
        cursor.y = 0;
    }
    
    public function render(g:Graphics, x:Float, y:Float):Void 
	{
        var currTileX = 0.0;
        var currTileY = 0.0;

        var posX:Int;
        var posY:Int;

        var sx:Float;
        var sy:Float;
        var w:Int;
        var h:Int;        

        for (i in 0...tileInfo.length)
        {
            posX = i * 2;
            posY = (i * 2) + 1;

            sx = region.sx;
            sy = region.sy;
            w = region.width;
            h = region.height;

            if ((tileInfo[posX] + cursor.x > width) || (tileInfo[posY] + cursor.y > height))
                continue;
            else
            {
                if (tileInfo[posX] < 0)
                {
                    sx = region.sx + region.width - cursor.x;

                    if (cursor.x < width)
                        w = Std.int(cursor.x);
                    else
                        w = width;

                    currTileX = x;
                }
                else 
                {
                    if (tileInfo[posX] + region.width + cursor.x > width)                    
                        w = Std.int(width - (tileInfo[posX] + cursor.x));
                    
                    currTileX = x + tileInfo[posX] + cursor.x;
                }

                if (tileInfo[posY] < 0)
                {
                    sy = region.sy + region.height - cursor.y;

                    if (cursor.y < height)
                        h = Std.int(cursor.y);
                    else
                        h = height;
                        
                    currTileY = y;
                }
                else 
                {
                    if (tileInfo[posY] + region.height + cursor.y > height)                    
                        h = Std.int(height - (tileInfo[posY] + cursor.y));

                    currTileY = y + tileInfo[posY] + cursor.y;
                }                    
            }
            
            g.drawScaledSubImage(region.image, sx, sy, w, h, currTileX, currTileY, w, h);                        
        }        
	}    

    function set_region(value:Region):Region
    {
        region = value;
        updateTileInfo();

        return value;
    }
}