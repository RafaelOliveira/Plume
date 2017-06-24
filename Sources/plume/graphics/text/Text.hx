package plume.graphics.text;

import kha.graphics2.Graphics;
import kha.Font;
import kha.math.FastVector2;
import kha.math.Vector2i;

enum TextAlign
{
	Left;
	Center;
	Right;
}

typedef TextOptions = {	
	@:optional var align:TextAlign;
	@:optional var lineSpacing:Int;
}

typedef Line = {
	var text:String;
	var width:Int;
}

class Text
{
	/**
	 * Text that will be rendered. The text is divided
	 * in lines according to the box width
	 */
	public var text(default, set):String;
	/**
	 * Changing the text or the box width will put
	 * textProcessed to false, this variable
	 * is used in update to check if the text needs to be
	 * divided in lines again
	 */
	var textProcessed:Bool;

	public var font(default, null):Font;

	public var fontSize(default, set):Int;
	
	var fontHeight:Int;

	public var align:TextAlign;
	public var lineSpacing:Int;

	/** 
	 * The width of the box that contain the text
	 */
	public var boxWidth(default, set):Int;		
	/** 
	 * The height of the box that contain the text. This is calculated 
	 *  automatically based on the number of lines. 
	 */	
	public var boxHeight(default, null):Int;
	/** 
	 * Trims trailing space characters 
	 */
	public var trimEnds:Bool; 
	/** 
	 * Trims ALL space characters (including mid-sentence) 
	 */
	public var trimAll:Bool;
	
	var cursor:FastVector2;
	
	var lines:Array<Line>;

	public function new(text:String, font:Font, fontSize:Int, boxWidth:Int = 0, ?option:TextOptions):Void
	{
		cursor = new FastVector2();
		this.text = text;

		// this will automatically put
		// textProcessed as false
		this.boxWidth = boxWidth;

		trimEnds = true;
		trimAll = true;

		// As update is called before render
		// the value for boxHeight will be available in render
		boxHeight = 0;

		this.font = font;				

		this.fontSize = fontSize;

		if (option != null)
		{
			if (option.align != null)
				align = option.align;
			else
				align = TextAlign.Left;

			if (option.lineSpacing != null)
				lineSpacing = option.lineSpacing;
			else
				lineSpacing = 3;
		}
		else
		{
			align = TextAlign.Left;
			lineSpacing = 3;
		}
		
		// process the text immediately to get the boxHeight
		update();
	}

	public function update():Void
	{
		if (textProcessed)
			return;

		// Array of lines that will be returned.
		lines = new Array<Line>();
		
		if (boxWidth <= 0)
		{
			lines.push({ text: text, width: Std.int(font.width(fontSize, text)) });
			return;
		}

		// Test the regex here: https://regex101.com/
		var trim1 = ~/^ +| +$/g; // removes all spaces at beginning and end
		var trim2 = ~/ +/g; // merges all spaces into one space
		var fullText = text;
		
		if (trimAll)
		{
			fullText = trim1.replace(fullText, ''); // remove trailing spaces first
			fullText = trim2.replace(fullText, ' '); // merge all spaces into one
		}
		else if (trimEnds)		
			fullText = trim1.replace(fullText, '');

		// split words by spaces
		// E.g. "This is a sentence"
		// becomes ["this", "is", "a", "sentence"]
		var words = fullText.split(' ');
		var wordsLen = words.length;
		var j = 1;

		// Add a space word in between every word.
		// E.g. ["this", "is", "a", "sentence"]
		// becomes ["this", " ", "is", " ", "a", " ", "sentence"]
		for (i in 0 ... wordsLen)
		{
			if (i != (wordsLen - 1))
			{
				words.insert(i + j, ' ');
				j++;
			}
		}

		// Reusable variables		
		var currLineText = '';
		var currLineWidth = 0;
		var currWord = '';
		var currWordWidth = 0;
		var isBreakFirst = false;
		var isBreakLater = false;
		var isLastWord = false;
		var reg = ~/[\n\r]/; // gets first occurence of line breaks
		var i = 0;
		var len = words.length;
		var lastLetterPadding = 0;

		while (i < words.length)
		{
			var thisWord = words[i];
			lastLetterPadding = 0;

			// If newline character exists, split the word for further
			// checking in the subsequent loops.
			if (reg.match(thisWord))
			{
				var splitIndex = reg.matchedPos();
				var splitWords = reg.split(thisWord);
				var firstWord = splitWords[0];
				var remainder = splitWords[1];

				// Replace current word with the splitted word
				words[i] = thisWord = firstWord;

				// Insert the remainder of the word into next index
				// and we'll check it again later.
				words.insert(i + 1, remainder);

				// Flag to break AFTER we process this word.
				isBreakLater = true;
			}
			else if (i == words.length - 1)
			{
				// If the word need not be split, then check if this
				// is the last word. If yes, then we can finalise this
				// line at the end.
				isLastWord = true;
			}

			// If this is a non-space word, let's process it.
			if (thisWord != ' ')
			{
				currWord = thisWord;
				currWordWidth = Std.int(font.width(fontSize, currWord));												
			}
			else
			{
				// For space characters, usually they have no width,
				// we have to manually add the .spaceWidth value.
				currWord = ' ';
				currWordWidth = Std.int(font.width(fontSize, ' '));				
			}

			// After adding current word to the line, did it pass
			// the text width? If yes, flag to break. Otherwise,
			// just update the current line.
			if ((currLineWidth + currWordWidth) <= boxWidth)
			{
				currLineText += currWord; // Add the word to the full line
				currLineWidth += currWordWidth; // Update the full width of the line
			}
			else
			{
				isBreakFirst = true;
			}

			// If we need to break the line first, add the
			// current line to the array first, then add the
			// current word to the next line.
			if (isBreakFirst || isLastWord)
			{								
				// Add current line (sans current word) to array
				lines.push({
					text: currLineText,
					width: currLineWidth
				});

				// If this isn't the last word, then begin the next
				// line with the current word.
				if (!isLastWord)
				{
					// If current word is a proper word:
					if (currWord != ' ')
					{
						// Next line begins with the current word
						currLineText = currWord;
						currLineWidth = currWordWidth;
					}
					else
					{
						// Ignore spaces; Reset the next line.
						currLineText = '';
						currLineWidth = 0;
					}

					isBreakFirst = false;
				}
				else if (isBreakFirst)
				{
					// If this is the last word, then just push it
					// to the next line and finish up.
					lines.push({
						text: currWord,
						width: currWordWidth
					});
				}

				// trim the text at start and end of the last line
				//if (trimAll) trim1.replace(lines[lines.length-1].text, '');
				if (trimAll) 
				{
					var position = lines.length - 1;
										
					lines[position].text = trim1.replace(lines[position].text, '');
					lines[position].width = Std.int(font.width(fontSize, lines[position].text));
				}
			}

			// If we need to break the line AFTER adding the current word
			// to the current line, do it here.
			if (isBreakLater)
			{
				// add current line to array, whether it has already
				// previously been broken to new line or not.

				lines.push({
					text: currLineText,
					width: currLineWidth
				});

				// Start next line afresh.
				currLineText = '';
				currLineWidth = 0;

				isBreakLater = false;
			}

			// move to next word
			currWord = '';
			currWordWidth = 0;

			// Move to next iterator.
			i++;
		}

		textProcessed = true;
		//boxHeight = Std.int(lines.length * ((font.lineHeight * scaleY) + lineSpacing));
		boxHeight = lines.length * (fontHeight + lineSpacing);
	}

	public function destroy():Void
	{
		font = null;
		cursor = null;		
	}

	public function render(g:Graphics, x:Float, y:Float):Void 
	{		
		g.font = font;
		g.fontSize = fontSize;

		// Reset cursor position
		cursor.x = 0;
		cursor.y = 0;		

		for (line in lines)
		{
			// NOTE:
			// Based on width and each line.width, we just
			// offset the starting cursor.x to make it look like
			// it's aligned to the correct side.
			if (boxWidth > 0)
			{
				switch (align)
				{
					case TextAlign.Left: cursor.x = 0;
					case TextAlign.Right: cursor.x = boxWidth - line.width;
					case TextAlign.Center: cursor.x = (boxWidth / 2) - (line.width / 2);
				}
			}						
						
			g.drawString(line.text, x + cursor.x, y + cursor.y);  							

			// After we finish rendering this line,
			// move on to the next line.
			cursor.y += fontHeight + lineSpacing;
		}		
	}
	
	public function getSize():Vector2i 
    {
		if (boxWidth > 0)
        	return new Vector2i(boxWidth, boxHeight);
		else
			return new Vector2i(getLineWidth(), fontHeight);
    }

	public function getLineWidth(index:Int = 0):Int
	{
		if (lines[index] != null)
			return lines[index].width;
		else
			return 0;
	}

	public function getLineText(index:Int = 0):String
	{
		if (lines[index] != null)
			return lines[index].text;
		else
			return '';
	}
	
	public function set_text(value:String):String
	{
		textProcessed = false;
		
		return text = value;
	}
	
	public function set_boxWidth(value:Int):Int
	{
		textProcessed = false;
		
		return boxWidth = value;
	}
	
	public function set_fontSize(value:Int):Int
	{
		fontHeight = Std.int(font.height(value));
		textProcessed = false;
		
		return fontSize = value;
	}
}