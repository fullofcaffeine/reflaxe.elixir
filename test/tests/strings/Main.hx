package;

using StringTools;

/**
 * String operations test case
 * Tests string manipulation, interpolation, and methods
 */
class Main {
	// String literals and concatenation
	public static function stringBasics(): Void {
		var str1 = "Hello";
		var str2 = 'World';
		var str3 = str1 + " " + str2;
		trace(str3);
		
		// Multi-line strings
		var multiline = "This is
a multi-line
string";
		trace(multiline);
		
		// String length
		trace('Length of "$str3": ${str3.length}');
	}
	
	// String interpolation
	public static function stringInterpolation(): Void {
		var name = "Alice";
		var age = 30;
		var pi = 3.14159;
		
		// Basic interpolation
		trace('Hello, $name!');
		trace('Age: $age');
		
		// Expression interpolation
		trace('Next year, $name will be ${age + 1}');
		trace('Pi rounded: ${Math.round(pi * 100) / 100}');
		
		// Interpolation with object fields
		var person = {name: "Bob", age: 25};
		trace('Person: ${person.name} is ${person.age} years old');
		
		// Complex expressions
		var items = ["apple", "banana", "orange"];
		trace('Items: ${items.join(", ")}');
		trace('First item: ${items[0].toUpperCase()}');
	}
	
	// String methods
	public static function stringMethods(): Void {
		var str = "  Hello, World!  ";
		
		// Trim
		trace('Trimmed: "${str.trim()}"');
		
		// Case conversion
		trace('Upper: ${str.toUpperCase()}');
		trace('Lower: ${str.toLowerCase()}');
		
		// Substring operations
		var text = "Hello, World!";
		trace('Substring(0, 5): ${text.substring(0, 5)}');
		trace('Substr(7, 5): ${text.substr(7, 5)}');
		
		// Character access
		trace('Char at 0: ${text.charAt(0)}');
		trace('Char code at 0: ${text.charCodeAt(0)}');
		
		// Index operations
		trace('Index of "World": ${text.indexOf("World")}');
		trace('Last index of "o": ${text.lastIndexOf("o")}');
		
		// Split and join
		var parts = text.split(", ");
		trace('Split parts: $parts');
		var joined = parts.join(" - ");
		trace('Joined: $joined');
		
		// Replace
		var replaced = text.replace("World", "Haxe");
		trace('Replaced: $replaced');
	}
	
	// String comparison
	public static function stringComparison(): Void {
		var str1 = "apple";
		var str2 = "Apple";
		var str3 = "apple";
		var str4 = "banana";
		
		// Equality
		trace('str1 == str3: ${str1 == str3}');
		trace('str1 == str2: ${str1 == str2}');
		
		// Comparison
		if (str1 < str4) {
			trace('$str1 comes before $str4');
		}
		
		// Case-insensitive comparison
		if (str1.toLowerCase() == str2.toLowerCase()) {
			trace('$str1 and $str2 are equal (case-insensitive)');
		}
	}
	
	// String building
	public static function stringBuilding(): Void {
		// Using StringBuf for efficient concatenation
		var buf = new StringBuf();
		buf.add("Building ");
		buf.add("a ");
		buf.add("string ");
		buf.add("efficiently");
		
		for (i in 0...3) {
			buf.add('!');
		}
		
		var result = buf.toString();
		trace('Built string: $result');
		
		// Building with array join
		var parts = [];
		for (i in 1...6) {
			parts.push('Item $i');
		}
		var list = parts.join(", ");
		trace('List: $list');
	}
	
	// Regular expressions
	public static function regexOperations(): Void {
		var text = "The year is 2024 and the time is 15:30";
		
		// Match digits
		var digitRegex = ~/\d+/;
		if (digitRegex.match(text)) {
			trace('First number found: ${digitRegex.matched(0)}');
		}
		
		// Match all numbers
		var allNumbers = ~/\d+/g;
		var numbers = [];
		var temp = text;
		while (allNumbers.match(temp)) {
			numbers.push(allNumbers.matched(0));
			temp = allNumbers.matchedRight();
		}
		trace('All numbers: $numbers');
		
		// Replace with regex
		var replaced = ~/\d+/.replace(text, "XXX");
		trace('Numbers replaced: $replaced');
		
		// Email validation pattern
		var email = "user@example.com";
		var emailRegex = ~/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
		trace('Is valid email: ${emailRegex.match(email)}');
	}
	
	// String formatting
	public static function stringFormatting(): Void {
		// Padding
		var num = 42;
		var padded = StringTools.lpad(Std.string(num), "0", 5);
		trace('Padded number: $padded');
		
		var text = "Hi";
		var rpadded = StringTools.rpad(text, " ", 10) + "|";
		trace('Right padded: $rpadded');
		
		// Hex encoding
		var hex = StringTools.hex(255);
		trace('255 in hex: $hex');
		
		// URL encoding (if supported)
		var url = "Hello World!";
		var encoded = StringTools.urlEncode(url);
		trace('URL encoded: $encoded');
		var decoded = StringTools.urlDecode(encoded);
		trace('URL decoded: $decoded');
	}
	
	// Unicode and special characters
	public static function unicodeStrings(): Void {
		var unicode = "Hello 世界 🌍";
		trace('Unicode string: $unicode');
		trace('Length: ${unicode.length}');
		
		// Escape sequences
		var escaped = "Line 1\nLine 2\tTabbed\r\nLine 3";
		trace('Escaped: $escaped');
		
		var quote = "She said \"Hello\"";
		trace('Quote: $quote');
		
		var backslash = "Path: C:\\Users\\Name";
		trace('Backslash: $backslash');
	}
	
	public static function main() {
		trace("=== String Basics ===");
		stringBasics();
		
		trace("\n=== String Interpolation ===");
		stringInterpolation();
		
		trace("\n=== String Methods ===");
		stringMethods();
		
		trace("\n=== String Comparison ===");
		stringComparison();
		
		trace("\n=== String Building ===");
		stringBuilding();
		
		trace("\n=== Regex Operations ===");
		regexOperations();
		
		trace("\n=== String Formatting ===");
		stringFormatting();
		
		trace("\n=== Unicode Strings ===");
		unicodeStrings();
	}
}