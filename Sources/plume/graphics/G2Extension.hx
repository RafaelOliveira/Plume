package plume.graphics;

import kha.math.Vector2;
import kha.graphics2.Graphics;

class G2Extension
{
	public static function drawEllipse(g2:Graphics, cx:Float, cy:Float, rx:Float, ry:Float, segments:Int = 0, strength:Float = 1):Void
	{
		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(rx));

		var x = rx, y = 0.0;
		var px:Float, py:Float;

		var angle:Float = 0.0;
		//var angle_stepsize:Float = 0.1;

		// go through all angles from 0 to 2 * PI radians
		while (angle < (2 * Math.PI))
		{
			px = x + cx;
			py = y + cy;

			// calculate x, y from a vector with known length and angle
			x = rx * Math.cos(angle);
			y = ry * Math.sin(angle);

			g2.drawLine(px, py, x + cx, y + cy, strength);
			angle += 2 * (Math.PI / segments);
		}

		g2.drawLine(x + cx, y + cy, rx + cx, cy, strength);
	}

	public static function fillEllipse(g2:Graphics, cx:Float, cy:Float, rx:Float, ry:Float, segments:Int = 0):Void
	{
		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(rx));

		var x = rx, y = 0.0;
		var px:Float, py:Float;

		var angle:Float = 0.0;
		//var angle_stepsize:Float = 0.1;

		// go through all angles from 0 to 2 * PI radians
		while (angle < (2 * Math.PI))
		{
			px = x + cx;
			py = y + cy;

			// calculate x, y from a vector with known length and angle
			x = rx * Math.cos(angle);
			y = ry * Math.sin(angle);

			//g2.drawLine(px, py, x + cx, y + cy, strength);
			g2.fillTriangle(cx, cy, px, py, x + cx, y + cy);

			angle += 2 * (Math.PI / segments);
		}

		g2.fillTriangle(cx, cy, x + cx, y + cy, rx + cx, cy);
	}

	/**
	* Draws a arc.
	* @param	x			X position of the arc's center.
	* @param	y			Y position of the arc's center.
	* @param	radius		Radius of the arc.
	* @param	start		The starting angle in radians.
	* @param	angle		The arc size in radians.
	* @param	segments	Increasing will smooth the arc but takes longer to render. Must be a value greater than zero.
	*/
	public static function drawArc(g2:Graphics, x:Float, y:Float, radius:Float, start:Float, angle:Float, segments:Int = 0, strength: Float = 1):Void
	{
		var radians = angle / segments;		

		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(radius));

		var theta = 0 * radians + start;

		var v0 = new Vector2(x + (Math.sin(theta) * radius), y + (Math.cos(theta) * radius));
		var v1 = new Vector2();

		for (segment in 1...segments)
		{
			theta = segment * radians + start;

			v1.x = x + (Math.sin(theta) * radius);
			v1.y = y + (Math.cos(theta) * radius);

			g2.drawLine(v0.x, v0.y, v1.x, v1.y, strength);

			v0.x = v1.x;
			v0.y = v1.y;
		}		
	}

	public static function fillArc(g2:Graphics, x:Float, y:Float, radius:Float, start:Float, angle:Float, segments:Int = 0):Void
	{
		var radians = angle / segments;		

		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(radius));

		var theta = 0 * radians + start;

		var v0 = new Vector2(x + (Math.sin(theta) * radius), y + (Math.cos(theta) * radius));
		var v1 = new Vector2();

		for (segment in 1...segments)
		{
			theta = segment * radians + start;

			v1.x = x + (Math.sin(theta) * radius);
			v1.y = y + (Math.cos(theta) * radius);
			
			g2.fillTriangle(x, y, v0.x, v0.y, v1.x, v1.y);

			v0.x = v1.x;
			v0.y = v1.y;
		}
	}

	/**
	* Draws a cubic bezier using 4 pairs of points. If the vertices have a length bigger then 4, the additional
	* points will be ignored. With a length smaller of 4 a error will occur, there is no check for this.
	* You can construct the curves visually in Inkscape with a path using default nodes.
	* Reference: http://devmag.org.za/2011/04/05/bzier-curves-a-tutorial/
	*/
	public static function drawCubicBezier(g2:Graphics, x:Float, y:Float, vertices:Array<Vector2>, segments:Int = 20, strength:Float = 1.0):Void
	{
		var t:Float;
		
		var q0 = calculateCubicBezierPoint(0, vertices);
		var q1:Array<Float>;
		
		for (i in 1...(segments + 1)) {
			t = i / segments;
			q1 = calculateCubicBezierPoint(t, vertices);
			g2.drawLine(x + q0[0], y + q0[1], x + q1[0], y + q1[1], strength);
			q0 = q1;
		}
	}
		
	/**
	* Draws multiple cubic beziers joined by the end point. The minimum size is 4 pairs of points (a single curve).	 
	*/
	public static function drawCubicBezierPath(g2:Graphics, x:Float, y:Float, vertices:Array<Vector2>, segments:Int = 20, strength:Float = 1.0):Void
	{
		var i = 0;
		var t:Float;
		var q0:Array<Float> = null;
		var q1:Array<Float> = null;

		while (i < vertices.length - 3) 
		{
			if (i == 0)
				q0 = calculateCubicBezierPoint(0, vertices.slice(i, i + 4));			

			for (j in 1...(segments + 1)) 
			{
				t = j / segments;
				q1 = calculateCubicBezierPoint(t, vertices.slice(i, i + 4));			
				g2.drawLine(x + q0[0], y + q0[1], x + q1[0], y + q1[1], strength);
				q0 = q1;
			}
			
			i += 3;
		}
	}

	public static function drawQuadraticBezier(g2:Graphics, x:Float, y:Float, vertices:Array<Vector2>, segments:Int = 25, strength:Float = 1.0):Void
	{
		var q0:Array<Float> = [vertices[0].x, vertices[0].y];
		var q1:Array<Float> = [0, 0];	
		
		var deltaT:Float = 1 / segments;
		
		for (segment in 1...segments)
		{
			var t:Float = segment * deltaT;

			q1[0] = (1 - t) * (1 - t) * vertices[0].x + 2 * t * (1 - t) * vertices[1].x + t * t * vertices[2].x;
			q1[1] = (1 - t) * (1 - t) * vertices[0].y + 2 * t * (1 - t) * vertices[1].y + t * t * vertices[2].y;

			g2.drawLine(x + q0[0], y + q0[1], x + q1[0], y + q1[1], strength);
			q0 = q1;
		}

		g2.drawLine(x + q1[0], y + q1[1], x + vertices[2].x, y + vertices[2].y, strength);
	}
		
	static function calculateCubicBezierPoint(t:Float, vertices:Array<Vector2>):Array<Float>
	{
		var u:Float = 1 - t;
		var tt:Float = t * t;
		var uu:Float = u * u;
		var uuu:Float = uu * u;
		var ttt:Float = tt * t;

		// first term
		var p:Array<Float> = [uuu * vertices[0].x, uuu * vertices[0].y];
			
		// second term				
		p[0] += 3 * uu * t * vertices[1].x;
		p[1] += 3 * uu * t * vertices[1].y;
			
		// third term
		p[0] += 3 * u * tt * vertices[2].x;
		p[1] += 3 * u * tt * vertices[2].y;
			
		// fourth term
		p[0] += ttt * vertices[3].x;
		p[1] += ttt * vertices[3].y;

		return p;
	}
}