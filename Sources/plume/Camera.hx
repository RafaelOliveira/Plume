package plume;

import kha.graphics2.Graphics;

@:allow(plume.State)
class Camera
{
    public var x:Float;
    public var y:Float;
    
    public var offsetX:Int;
    public var offsetY:Int;

    public var viewPortX(get, never):Float;
    public var viewPortY(get, never):Float;
    
    public var width:Int;
    public var height:Int;
    public var halfWidth:Int;
    public var halfHeight:Int;
    
    var dzLeft:Int;
    var dzRight:Int;
    var dzTop:Int;
    var dzBottom:Int;

    var shakeTime:Float = 0;
	var shakeMagnitude:Int = 0;
	var shakeX:Int = 0;
	var shakeY:Int = 0;	    
    
    public function new(width:Int, height:Int):Void
    {
        x = 0;
        y = 0;
        offsetX = 0;
        offsetY = 0;
        
        this.width = width;
        this.height = height;
        halfWidth = Std.int(width / 2);
        halfHeight = Std.int(height / 2);
        
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

    public function setOffset(offsetX:Int, offsetY:Int):Void
    {
        this.offsetX = offsetX;
        this.offsetY = offsetY;
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
        if (objX > dzLeft && objX < (Plm.state.worldWidth - dzRight))
            x = objX - halfWidth;
            
        if (objY > dzTop && objY < (Plm.state.worldHeight - dzBottom))
            y = objY - halfHeight;

        checkBoundaries();
    }
        
    public function centerOnPos(px:Float, py:Float):Void
    {
        x = px - halfWidth + offsetX;
        y = py - halfHeight + offsetY;

        checkBoundaries();
    }

    function checkBoundaries():Void
    {
        if (x < 0)
            x = 0;
        else if (x + width - offsetX > Plm.state.worldWidth)
            x = Plm.state.worldWidth - width + offsetX;
        
        if (y < 0)
            y = 0;
        else if (y + height - offsetY > Plm.state.worldHeight)
            y = Plm.state.worldHeight - height + offsetY;
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

    public function shake(magnitude:Int, duration:Float)
	{
		if (shakeTime < duration) 
            shakeTime = duration;

		shakeMagnitude = magnitude;
	}

    /** Stop the screen from shaking immediately. */
	public function shakeStop()
	{
		shakeTime = 0;
	}

    function update():Void
	{
        // update screen shake
		if (shakeTime > 0)
		{
			var sx:Int = Std.random(shakeMagnitude * 2 + 1) - shakeMagnitude;
			var sy:Int = Std.random(shakeMagnitude * 2 + 1) - shakeMagnitude;

			x += sx - shakeX;
			y += sy - shakeY;

			shakeX = sx;
			shakeY = sy;

			shakeTime -= Plm.dt;
			if (shakeTime < 0) shakeTime = 0;
		}
		else if (shakeX != 0 || shakeY != 0)
		{
			x -= shakeX;
			y -= shakeY;
			shakeX = shakeY = 0;
		}
	}

    public function begin(g:Graphics):Void
	{
		g.pushTranslation(-x + offsetX,	-y + offsetY);

		if (Plm.state.cameras.length > 1)		
			g.scissor(Std.int(offsetX), Std.int(offsetY), width, height);
	}

	public inline function end(g:Graphics):Void
	{
		g.popTransformation();
		 
		if (Plm.state.cameras.length > 1)		
			g.disableScissor();
	}

    inline function get_viewPortX():Float
    {
        return x + offsetX;
    }

    inline function get_viewPortY():Float
    {
        return y + offsetY;
    }
}