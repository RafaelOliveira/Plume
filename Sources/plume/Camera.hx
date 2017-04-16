package plume;

class Camera
{
    public var x:Float;
    public var y:Float;
    
    public var width:Int;
    public var height:Int;
    public var halfWidth:Int;
    public var halfHeight:Int;
    public var worldWidth:Int;
    public var worldHeight:Int;
    
    public var dzLeft:Int;
    public var dzRight:Int;
    public var dzTop:Int;
    public var dzBottom:Int;    
    
    public function new():Void
    {
        x = 0;
        y = 0;        
        
        width = Plm.gameWidth;
        height = Plm.gameHeight;
        halfWidth = Std.int(width / 2);
        halfHeight = Std.int(height / 2);

        worldWidth = width;
        worldHeight = height;
        
        dzLeft = 0;
        dzRight = 0;
        dzTop = 0;
        dzBottom = 0;
    }
    
    public function setSize(width:Int, height:Int):Void
    {
        this.width = width;
        this.height = height;
        halfWidth = Std.int(width / 2);
        halfHeight = Std.int(height / 2);
    }

    public function setWorldSize(width:Int, height:Int):Void
    {
        this.worldWidth = width;
        this.worldHeight = height;        
    }
    
    public function setDeadZones(left:Int, right:Int, top:Int, bottom:Int):Void
    {
        dzLeft = left;
        dzRight = right;
        dzTop = top;
        dzBottom = bottom;
    }
    
    public function follow(objX:Float, objY:Float):Void
    {
        if (objX > dzLeft && objX < (worldWidth - dzRight))
            x = objX - halfWidth;
            
        if (objY > dzTop && objY < (worldHeight - dzBottom))
            y = objY - halfHeight;

        checkBoundaries();
    }
        
    public function center(px:Float, py:Float):Void
    {
        x = px - halfWidth;
        y = py - halfHeight;

        checkBoundaries();
    }

    function checkBoundaries():Void
    {
        if (x < 0)
            x = 0;
        else if (x + width > worldWidth)
            x = worldWidth - width;
        
        if (y < 0)
            y = 0;
        else if (y + height > worldHeight)
            y = worldHeight - height;
    }
    
    public function moveBy(stepX:Float, stepY:Float):Void
    {
        if (stepX < 0)
        {
            if ((x + stepX) > 0)
                x += stepX;
            else
                x = 0;
        }
        else
        {
            if ((x + Plm.gameWidth + stepX) < width)
                x += stepX;
            else
                x = width - Plm.gameWidth;
        }
        
        if (stepY < 0)
        {
            if ((y + stepY) > 0)
                y += stepY;
            else
                y = 0;
        }
        else
        {
            if ((y + Plm.gameHeight + stepY) < height)
                y += stepY;
            else
                y = height - Plm.gameHeight;
        }
    }
}