package plume.graphics;

import kha.graphics2.Graphics;
import kha.graphics2.GraphicsExtension;


public static function drawEllipse(g2:Graphics, cx:Float, cy:Float, rx:Float, ry:Float, strength:Float = 1, segments:Int = 0):Void
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