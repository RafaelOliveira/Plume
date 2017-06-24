package plume.graphics.text;

import haxe.Utf8;
import haxe.xml.Fast;
import kha.Image;
import kha.graphics2.Graphics;
import kha.Color;
import kha.Assets;
import kha.Blob;
import kha.math.FastVector2;
import kha.math.Vector2i;
import plume.graphics.text.Text.TextAlign;
import plume.graphics.text.Text.TextOptions;
import plume.graphics.text.Text.Line;
import plume.atlas.Atlas.ImageType;
import plume.math.Vector2b;
import plume.atlas.Region;

/**
	Tip on how to generate Bitmap font, for Windows AND Mac:
	- use BMFont.exe (www.angelcode.com/products/bmfont/)
	- For mac, install Wine (easily install via Brew)
	- Best setup for BMFont by @laxa88:
		- go to Options > Font Settings
		- Load font (make sure the font is installed)
		- Leave everything as default
		- go to Options > Export Options
		- CHECK Force offsets to zero (quirk: if unchecked, letter kernings may get weird)
		- Make sure texture size is big enough, so that all letters fit in one graphic (mine is 512x512)
		- Bit depth = 32
		- Channel - A = glyph, R/G/B = one
		- Presets - White text with alpha
		- Font description - XML (required for BitmapText to parse data)
		- Textures - PNG
	- Once done setup, just click Options > Save bitmap font as...
	- Copy the generated PNG and FNT file to your kha assets folder and use normally.
 */
	
 typedef BitmapFont = {
	var size:Int;
	var outline:Int;
	var lineHeight:Int;
	var spaceWidth:Int;
	var region:Region;
	var letters:Array<BitmapLetter>;
}

typedef BitmapLetter = {
	var id:Int;
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var xoffset:Int;
	var yoffset:Int;
	var xadvance:Int;
	var kernings:Map<Int, Int>;
}
	
class BitmapText
{
	static var spaceCharCode:Int = ' '.charCodeAt(0);
	/** 
	 * Stores a list of all bitmap fonts into a dictionary 
	 */
	static var fontCache:Map<String, BitmapFont>;
	
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
	
	public var font(default, null):BitmapFont;
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
	 * Scaling factor in the x axis
	 */
	public var scaleX:Float;
	/**
	 * Scaling factor in the y axis
	 */
	public var scaleY:Float;
	/**
	 * If the sprite should be rendered flipped
	 */
	public var flip:Vector2b;
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
	
	/** 
	 * Variable for rendering purposes 
	 */
	var letterWidthScaled:Float;
	/** 
	 * Variable for rendering purposes 
	 */
	var letterHeightScaled:Float;

	var _kerningSize:Null<Int>;
	
	/**
	 * Loads the bitmap font from cache. Remember to call loadFont first before
	 * creating new a BitmapText.
	 */
	public function new(text:String, fontName:String, boxWidth:Int = 0, ?option:TextOptions):Void
	{		
		cursor = new FastVector2();		

		if (fontCache != null && fontCache.exists(fontName))
		{
			this.text = text;
			
			// this will automatically put
			// textProcessed as false
			this.boxWidth = boxWidth;
			
			trimEnds = true;
			trimAll = true;
			
			scaleX = 1;
			scaleY = 1;
			flip = new Vector2b();

			lines = new Array<Line>();
			
			// As update is called before render
			// the value for boxHeight will be available in render
			boxHeight = 0;

			font = fontCache.get(fontName);

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
		}
		else			
			trace('(new) Failed to init BitmapText with "${fontName}"');
		
		// process the text immediately to get the boxHeight
		update();
	}
	
	public function update():Void
	{
		if (textProcessed)
			return;

		// Array of lines that will be returned.
		//lines = new Array<Line>();

		if (boxWidth <= 0)
		{
			lines[0] = { text: text, width: 0 };

			if (lines.length > 1)
				lines.splice(1, lines.length - 1);

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
		var char:String;
		var charCode:Int;
		var letter:BitmapLetter;
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
		var indexNextLine = 0;

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
				for (charIndex in 0 ... thisWord.length)
				{
					char = thisWord.charAt(charIndex);
					charCode = Utf8.charCodeAt(char, 0);

					// Get letter data based on the charCode key
					letter = font.letters[charCode];

					// If the letter data exists, append it to the current word.
					// Then add the letter's padding to the overall word width.
					// If the letter data doesn't exist, then just skip without
					// altering the currWord or currWordWidth.
					if (letter != null)
					{
						currWord += char;
						currWordWidth += letter.xadvance;

						// If this is the last letter for the line, remember
						// the padding so that we can add to the currLineWidth later.
						lastLetterPadding = letter.width - letter.xadvance;
					}
				}
			}
			else
			{
				// For space characters, usually they have no width,
				// we have to manually add the .spaceWidth value.
				currWord = ' ';
				currWordWidth = font.spaceWidth;
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
				// Add padding so the last letter doesn't get chopped off
				currLineWidth += lastLetterPadding;

				// Add current line (sans current word) to array
				lines[indexNextLine] = {
					text: currLineText,
					width: currLineWidth
				};

				indexNextLine++;

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
					lines[indexNextLine] = {
						text: currWord,
						width: currWordWidth
					};

					indexNextLine++;
				}

				// trim the text at start and end of the last line
				if (trimAll)
				{
					var position = lines.length - 1;					
					var lenghtBeforeTrim = lines[position].text.length;
					
					lines[position].text = trim1.replace(lines[position].text, '');
					//lines[position].text = StringTools.trim(lines[position].text);
					
					// recalculating the size if spaces were removed
					if (lines[position].text.length < lenghtBeforeTrim)					
						lines[position].width -= (lenghtBeforeTrim - lines[position].text.length) * font.spaceWidth;					
				}
			}

			// If we need to break the line AFTER adding the current word
			// to the current line, do it here.
			if (isBreakLater)
			{
				// Add padding so the last letter doesn't get chopped off
				currLineWidth += lastLetterPadding;

				// add current line to array, whether it has already
				// previously been broken to new line or not.

				lines[indexNextLine] = {
					text: currLineText,
					width: currLineWidth
				};

				indexNextLine++;

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

		if ((lines.length - 1) >= indexNextLine)
			lines.splice(indexNextLine, lines.length - indexNextLine);
		
		textProcessed = true;
		boxHeight = Std.int(lines.length * ((font.lineHeight * scaleY) + lineSpacing));
	}

	static function getStringWidth(text:String, font:BitmapFont):Int
	{
		var char:String = '';
		var charCode:Int;
		var letter:BitmapLetter = null;		
		var textWidth:Int = 0;

		for (charIndex in 0...text.length)
		{
			char = text.charAt(charIndex);

			if (char != ' ')
			{
				charCode = Utf8.charCodeAt(char, 0);
				letter = font.letters[charCode];

				if (letter != null)				
					textWidth += letter.xadvance;
			}
			else
				textWidth += font.spaceWidth;
		}

		if (char != ' ' && letter != null)
			textWidth += letter.width - letter.xadvance;

		return textWidth;
	}	
	
	public function destroy():Void
	{
		font = null;
		cursor = null;		
	}
	
	public function render(g:Graphics, x:Float, y:Float):Void 
	{		
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
					case TextAlign.Center: cursor.x = Std.int((boxWidth * 0.5) - (line.width * 0.5));
				}
			}		

			var lineText:String = line.text;
			var lineTextLen:Int = lineText.length;

			for (i in 0 ... lineTextLen)
			{
				var char = lineText.charAt(i); // get letter
				var charCode = Utf8.charCodeAt(char, 0); // get letter id
				var letter = font.letters[charCode]; // get letter data

				// If the letter data exists, then we will render it.
				if (letter != null)
				{
					// If the letter is NOT a space, then render it.
					if (letter.id != spaceCharCode)
					{
						letterWidthScaled = letter.width * scaleX;
						letterHeightScaled = letter.height * scaleY;
						
						g.drawScaledSubImage(
							font.region.image,
							font.region.sx + letter.x,
							font.region.sy + letter.y,
							letter.width,
							letter.height,
							x + cursor.x + letter.xoffset * scaleX + (flip.x ? letterWidthScaled : 0),
							y + cursor.y + letter.yoffset * scaleX + (flip.y ? letterHeightScaled : 0),
							flip.x ? -letterWidthScaled : letterWidthScaled,
							flip.y ? -letterHeightScaled : letterHeightScaled);

						// Add kerning if it exists. Also, we don't have to
						// do this if we're already at the last character.
						if (i != lineTextLen)
						{
							// Get next char's code
							var charNext = lineText.charAt(i + 1);
							var charCodeNext = Utf8.charCodeAt(charNext, 0);

							// If kerning data exists, adjust the cursor position.
							if (letter.kernings != null && (_kerningSize = letter.kernings.get(charCodeNext)) != null)
							//if (_kerningSize != null)
								cursor.x += _kerningSize * scaleX;
						}

						// Move cursor to next position, with padding.
						cursor.x += (letter.xadvance + font.outline) * scaleX;
					}
					else
					{
						// If this is a space character, move cursor
						// without rendering anything.
						cursor.x += font.spaceWidth * scaleX;
					}
				}									
			}

			// After we finish rendering this line,
			// move on to the next line.
			cursor.y += (font.lineHeight * scaleY) + lineSpacing;
		}		
	}
	
	public function setScale(value:Float):Void
	{
		scaleX = value;
		scaleY = value;
	}
	
	public function getSize():Vector2i 
    {
        if (boxWidth > 0)
			return new Vector2i(boxWidth, boxHeight);
		else
			return new Vector2i(getLineWidth(), font.lineHeight);
    }
	
	public function getLineWidth(index:Int = 0):Int
	{
		if (lines[index] != null)
		{
			if (lines[index].width == 0)
				lines[index].width = getStringWidth(lines[index].text, font);

			return lines[index].width;			 
		}
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
	
	/**
	 * Do this first before creating a new BitmapText, because we
	 * need to process the font data before using.
	 */
	public static function loadFont(fontName:String, sourceImage:ImageType, fontData:Blob, loadKerning:Bool = false):Void
	{
		var region:Region = null;

		switch (sourceImage.type)
		{
			case First(img):
				region = Region.createFromImage(img);
			
			case Second(reg):
				region = reg;

			case Third(regName):
				region = Region.get(regName);
		}		
		
		// We'll store each letter's data into a dictionary here later.
		var letters = new Array<BitmapLetter>();

		var blobString:String = fontData.toString();
		var fullXml:Xml = Xml.parse(blobString);
		var fontNode:Xml = fullXml.firstElement();
		var data = new Fast(fontNode);

		// If the font file doesn't have a ' ' character,
		// this will be a default spacing for it.
		var spaceWidth = 8;

		// NOTE: Each of these attributes are in the .fnt XML data.
		var chars = data.node.chars;
		for (char in chars.nodes.char)
		{
			var letter:BitmapLetter = {
				id: Std.parseInt(char.att.id),
				x: Std.parseInt(char.att.x),
				y: Std.parseInt(char.att.y),
				width: Std.parseInt(char.att.width),
				height: Std.parseInt(char.att.height),
				xoffset: Std.parseInt(char.att.xoffset),
				yoffset: Std.parseInt(char.att.yoffset),
				xadvance: Std.parseInt(char.att.xadvance),
				kernings: null
			};

			if (loadKerning)
				letter.kernings = new Map<Int, Int>();

			// NOTE on xadvance:
			// http://www.angelcode.com/products/bmfont/doc/file_format.html
			// xadvance is the padding before the next character
			// is rendered. Spaces may have no width, so we assign
			// them here specifically for use later. Otherwise,
			// every other letter data has no spaceWidth value.
			if (letter.id == spaceCharCode)
				spaceWidth = letter.xadvance;

			// Save the letter's data into the dictioanry
			letters[letter.id] = letter;
			
			/*if (letter.id > letters.length)
			{
				while (letter.id != letters.length)
					letters.set(letters.length, null);
			}

			letters.set(letter.id, letter);*/
		}

		// If this fnt XML has kerning data for each letter,
		// process them here. Kernings are UNIQUE padding
		// between each letter to create a pleasing visual.
		// As an idea, Bevan.ttf has about 1000+ kerning data.
		if (loadKerning && data.hasNode.kernings)
		{
			var kernings = data.node.kernings;
			var letter:BitmapLetter;
			for (kerning in kernings.nodes.kerning)
			{
				var firstId = Std.parseInt(kerning.att.first);
				var secondId = Std.parseInt(kerning.att.second);
				var amount = Std.parseInt(kerning.att.amount);

				letter = letters[firstId];
				letter.kernings.set(secondId, amount);
			}
		}

		// Create the dictionary if it doesn't exist yet
		if (fontCache == null)
			fontCache = new Map<String, BitmapFont>();

		// Create new font data
		var font:BitmapFont = {
			size: Std.parseInt(data.node.info.att.size), // this original size this font's image was exported as
			outline: Std.parseInt(data.node.info.att.outline), // outlines are considered padding too
			lineHeight: Std.parseInt(data.node.common.att.lineHeight), // original vertical padding between texts
			spaceWidth: spaceWidth, // remember, this is only for space character
			region: region, // the font image sheet
			letters: letters // each letter's data
		}

		// Add this font data to dictionary, finally.
		fontCache.set(fontName, font);
	}
}