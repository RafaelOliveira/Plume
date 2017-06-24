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
	public var onCompleteFunc:Void->Void;
	
	public function new(name:String, regions:Array<Region>, fps:Int, ?onCompleteFunc:Void->Void):Void
	{
		this.name = name;
		this.regions = regions;
		this.fps = fps;
		this.onCompleteFunc = onCompleteFunc;
	}
}

class SpriteAnim
{
	/**
	 * The internal sprite, 
	 * used to scale and flip the rendering
	*/
	public var sprite:Sprite;
	/**
	 * The width that will rendered. Change only after play the first animation.
	 * Before that the sprite doesn't has a graphic (the internal sprite is null).
	 */
	public var width(get, set):Int;
	/**
	 * The height that will be rendered. Change only after play the first animation.
	 * Before that the sprite doesn't has a graphic (the internal sprite is null).
	 */
	public var height(get, set):Int;
	/**
	 * If the sprite should be rendered flipped in x. Change only after play the first animation.
	 * Before that the sprite doesn't has a graphic (the internal sprite is null).
	 */
	public var flipX(get, set):Bool;
	/**
	 * If the sprite should be rendered flipped in y. Change only after play the first animation.
	 * Before that the sprite doesn't has a graphic (the internal sprite is null).
	 */
	public var flipY(get, set):Bool;

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
	
	public function new():Void
	{
		active = false;	
		direction = 1;
		currIndex = 0;
		loop = false;
		autoReverse = false;
		elapsed = 0;
		nameAnim = '';		
		
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
				if (currAnimation.onCompleteFunc != null)
					currAnimation.onCompleteFunc();

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
				if (currAnimation.onCompleteFunc != null)
					currAnimation.onCompleteFunc();
					
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
		sprite.region = currAnimation.regions[currIndex];		
	}
	
	public function destroy():Void
	{		
		currAnimation = null;
		animations = null;
	}
	
	public function addAnimation(name:String, regions:Array<Region>, fps:Int = 12, ?onCompleteFunc:Void->Void):Void
	{
		if (animations.exists(name))
			trace('animation $name already exists, overwriting...');

		animations.set(name, new AnimData(name, regions, fps, onCompleteFunc));
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

			if (sprite == null)
				sprite = new Sprite(currAnimation.regions[currIndex]);
			else
				sprite.region = currAnimation.regions[currIndex];
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

	inline public function render(g:Graphics, x:Float, y:Float):Void 
	{
		sprite.render(g, x, y);
	}

	inline function get_width():Int
	{
		return sprite.width;
	}

	inline function set_width(value:Int):Int
	{
		sprite.width = value;

		return value;
	}

	inline function get_height():Int
	{
		return sprite.height;
	}

	inline function set_height(value:Int):Int
	{
		sprite.height = value;

		return value;
	}

	inline function get_flipX():Bool
	{
		return sprite.flipX;
	}

	inline function set_flipX(value:Bool):Bool
	{
		sprite.flipX = value;

		return value;
	}

	inline function get_flipY():Bool
	{
		return sprite.flipY;
	}

	inline function set_flipY(value:Bool):Bool
	{
		sprite.flipY = value;

		return value;
	}
}