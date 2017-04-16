package plume.graphics;

import kha.graphics2.Graphics;
import plume.math.Vector2b;
import plume.atlas.Region;
import plume.Plm;

// TODO: Optimize for animations of one frame

class AnimData 
{
	public var name:String;	
	public var regions:Array<Region>;
	public var fps:Int;
	
	public function new(name:String, regions:Array<Region>, fps:Int):Void
	{
		this.name = name;
		this.regions = regions;
		this.fps = fps;
	}
}

class SpriteAnim
{
	var region:Region;

	var active:Bool;

	/**
	 * positive = forward, negative = backwards 
	 */
	var direction:Float; 
	
	var animations:Map<String, AnimData>;	
	
	var currAnimation:AnimData;
	
	var currIndex:Int;
		
	var loop:Bool;

	var autoReverse:Bool;
	
	var elapsed:Float;	
	/** 
	 * The name of the current animation 
	 */
	public var nameAnim(default, null):String;
	/**
	 * If the sprite should be rendered flipped
	 */
	public var flip:Vector2b;
	
	public function new():Void
	{
		active = true;	
		direction = 1;
		currIndex = 0;
		loop = false;
		autoReverse = false;
		elapsed = 0;
		nameAnim = '';
		flip = new Vector2b();
		
		animations = new Map<String, AnimData>();
	}
		
	public function update():Void
	{
		if (!active)
			return;

		elapsed += Plm.dt * Math.abs(direction);

		// next frame
		if (elapsed >= 1 / currAnimation.fps)
		{
			elapsed -= (1 / currAnimation.fps);

			currIndex += (direction >= 0) ? 1 : -1;

			if (currIndex >= currAnimation.regions.length)
			{
				if (!loop)
				{
					stop();
					return;
				}
				
				if (!autoReverse)
					currIndex = 0;
				else
				{
					currIndex = currAnimation.regions.length - 1;
					reverse();
				}
			}					
			else if (currIndex < 0)
			{
				if (!loop)
				{
					stop();
					return;
				}						
				
				if (!autoReverse)
					currIndex = currAnimation.regions.length - 1;
				else
				{
					currIndex = 0;
					reverse();
				}
			}					
		}

		// update region
		region = currAnimation.regions[currIndex];		
	}
	
	public function destroy():Void
	{		
		currAnimation = null;
		animations = null;
	}
	
	public function addAnimation(name:String, regions:Array<Region>, fps:Int = 12):Void
	{
		if (animations.exists(name))
			trace('animation $name already exists, overwriting...');

		animations.set(name, new AnimData(name, regions, fps));		
	}
	
	public function removeAnimation(name:String):Void
	{
		animations.remove(name);
	}
	
	/**
	* Play a animation. Don't call this all the time,
	* Check first if the animation that will be played
	* is already running. To do this, compare the name
	* of the animation with nameAnim
	*/	
	public function play(name:String, loop:Bool = true, autoReverse:Bool = false, index:Int = 0)
	{		
		var animData:AnimData = animations.get(name);

		if (animData != null)
		{			
			currAnimation = animData;
			nameAnim = animData.name;
			this.loop = loop;
			this.autoReverse = autoReverse;

			restart(index);

			region = currAnimation.regions[currIndex];
		}
		else
		{
			trace('animation $name does not exist');
			return;
		}	
	}
	
	inline public function pause()
	{
		active = false;
	}
	
	inline public function resume()
	{
		active = true;
	}

	inline public function isRunning():Bool
	{
		return active;
	}

	inline public function isReversed():Bool
	{
		return (direction == -1);
	}

	public function stop()
	{
		active = false;
		currIndex = 0;
		elapsed = 0;
		nameAnim = '';
	}
	
	public function restart(index:Int = 0)
	{
		active = true;
		currIndex = index;
		elapsed = 0;
	}
	
	/**
	* Reverses the animation 
	*/
	public function reverse():Void
	{
		direction *= -1;		
	}

	public function render(g:Graphics, x:Float, y:Float):Void 
	{
		g.drawScaledSubImage(region.image, region.sx, region.sy, region.w, region.h,
			x + (flip.x ? region.w : 0),
			y + (flip.y ? region.h : 0), 
			flip.x ? -region.w : region.w, flip.y ? -region.h : region.h);
	}
}