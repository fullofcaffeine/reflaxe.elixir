defmodule Main do
  def string_basics() do
    str1 = "Hello"
    str2 = "World"
    str3 = str <> " " <> str
    Log.trace(str, %{:fileName => "Main.hx", :lineNumber => 15, :className => "Main", :methodName => "stringBasics"})
    multiline = "This is\na multi-line\nstring"
    Log.trace(multiline, %{:fileName => "Main.hx", :lineNumber => 21, :className => "Main", :methodName => "stringBasics"})
    Log.trace("Length of \"" <> str <> "\": " <> str.length, %{:fileName => "Main.hx", :lineNumber => 24, :className => "Main", :methodName => "stringBasics"})
  end
  def string_interpolation() do
    name = "Alice"
    age = 30
    pi = 3.14159
    Log.trace("Hello, " <> name <> "!", %{:fileName => "Main.hx", :lineNumber => 34, :className => "Main", :methodName => "stringInterpolation"})
    Log.trace("Age: " <> age, %{:fileName => "Main.hx", :lineNumber => 35, :className => "Main", :methodName => "stringInterpolation"})
    Log.trace("Next year, " <> name <> " will be " <> (age + 1), %{:fileName => "Main.hx", :lineNumber => 38, :className => "Main", :methodName => "stringInterpolation"})
    Log.trace("Pi rounded: " <> Std.int(pi * 100 + 0.5) / 100, %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "stringInterpolation"})
    person_name = nil
    person_age = nil
    person_name = "Bob"
    person_age = 25
    Log.trace("Person: " <> person_name <> " is " <> person_age <> " years old", %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "stringInterpolation"})
    items = ["apple", "banana", "orange"]
    Log.trace("Items: " <> Enum.join(items, ", "), %{:fileName => "Main.hx", :lineNumber => 47, :className => "Main", :methodName => "stringInterpolation"})
    Log.trace("First item: " <> items[0].toUpperCase(), %{:fileName => "Main.hx", :lineNumber => 48, :className => "Main", :methodName => "stringInterpolation"})
  end
  def string_methods() do
    str = "  Hello, World!  "
    Log.trace("Trimmed: \"" <> StringTools.ltrim(StringTools.rtrim(str)) <> "\"", %{:fileName => "Main.hx", :lineNumber => 56, :className => "Main", :methodName => "stringMethods"})
    Log.trace("Upper: " <> str.toUpperCase(), %{:fileName => "Main.hx", :lineNumber => 59, :className => "Main", :methodName => "stringMethods"})
    Log.trace("Lower: " <> str.toLowerCase(), %{:fileName => "Main.hx", :lineNumber => 60, :className => "Main", :methodName => "stringMethods"})
    text = "Hello, World!"
    Log.trace("Substring(0, 5): " <> text.substring(0, 5), %{:fileName => "Main.hx", :lineNumber => 64, :className => "Main", :methodName => "stringMethods"})
    Log.trace("Substr(7, 5): " <> text.substr(7, 5), %{:fileName => "Main.hx", :lineNumber => 65, :className => "Main", :methodName => "stringMethods"})
    Log.trace("Char at 0: " <> text.charAt(0), %{:fileName => "Main.hx", :lineNumber => 68, :className => "Main", :methodName => "stringMethods"})
    Log.trace("Char code at 0: " <> text.charCodeAt(0), %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "stringMethods"})
    Log.trace("Index of \"World\": " <> text.indexOf("World"), %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "stringMethods"})
    Log.trace("Last index of \"o\": " <> text.lastIndexOf("o"), %{:fileName => "Main.hx", :lineNumber => 73, :className => "Main", :methodName => "stringMethods"})
    parts = text.split(", ")
    Log.trace("Split parts: " <> Std.string(parts), %{:fileName => "Main.hx", :lineNumber => 77, :className => "Main", :methodName => "stringMethods"})
    joined = Enum.join(parts, " - ")
    Log.trace("Joined: " <> joined, %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "stringMethods"})
    replaced = StringTools.replace(text, "World", "Haxe")
    Log.trace("Replaced: " <> replaced, %{:fileName => "Main.hx", :lineNumber => 83, :className => "Main", :methodName => "stringMethods"})
  end
  def string_comparison() do
    str1 = "apple"
    str2 = "Apple"
    str3 = "apple"
    str4 = "banana"
    Log.trace("str1 == str3: " <> Std.string(str == str), %{:fileName => "Main.hx", :lineNumber => 94, :className => "Main", :methodName => "stringComparison"})
    Log.trace("str1 == str2: " <> Std.string(str == str), %{:fileName => "Main.hx", :lineNumber => 95, :className => "Main", :methodName => "stringComparison"})
    if (str < str) do
      Log.trace("" <> str <> " comes before " <> str, %{:fileName => "Main.hx", :lineNumber => 99, :className => "Main", :methodName => "stringComparison"})
    end
    if (str.toLowerCase() == str.toLowerCase()) do
      Log.trace("" <> str <> " and " <> str <> " are equal (case-insensitive)", %{:fileName => "Main.hx", :lineNumber => 104, :className => "Main", :methodName => "stringComparison"})
    end
  end
  def string_building() do
    buf = StringBuf.new()
    buf.add("Building ")
    buf.add("a ")
    buf.add("string ")
    buf.add("efficiently")
    buf.add("!")
    buf.add("!")
    buf.add("!")
    result = IO.iodata_to_binary(buf)
    Log.trace("Built string: " <> result, %{:fileName => "Main.hx", :lineNumber => 122, :className => "Main", :methodName => "stringBuilding"})
    parts = []
    parts = parts ++ ["Item " <> 1]
    parts = parts ++ ["Item " <> 2]
    parts = parts ++ ["Item " <> 3]
    parts = parts ++ ["Item " <> 4]
    parts = parts ++ ["Item " <> 5]
    list = Enum.join(parts, ", ")
    Log.trace("List: " <> list, %{:fileName => "Main.hx", :lineNumber => 130, :className => "Main", :methodName => "stringBuilding"})
  end
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"
    digit_regex = EReg.new("\\d+", "")
    if (digit_regex.match(text)) do
      Log.trace("First number found: " <> digit_regex.matched(0), %{:fileName => "Main.hx", :lineNumber => 140, :className => "Main", :methodName => "regexOperations"})
    end
    all_numbers = EReg.new("\\d+", "g")
    numbers = []
    temp = text
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {temp, all_numbers, :ok}, fn _, {acc_temp, acc_all_numbers, acc_state} ->
  if (acc_all_numbers.match(acc_temp)) do
    numbers.push(acc_all_numbers.matched(0))
    acc_temp = acc_all_numbers.matchedRight()
    {:cont, {acc_temp, acc_all_numbers, acc_state}}
  else
    {:halt, {acc_temp, acc_all_numbers, acc_state}}
  end
end)
    Log.trace("All numbers: " <> Std.string(numbers), %{:fileName => "Main.hx", :lineNumber => 151, :className => "Main", :methodName => "regexOperations"})
    replaced = EReg.new("\\d+", "").replace(text, "XXX")
    Log.trace("Numbers replaced: " <> replaced, %{:fileName => "Main.hx", :lineNumber => 155, :className => "Main", :methodName => "regexOperations"})
    email = "user@example.com"
    email_regex = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
    Log.trace("Is valid email: " <> Std.string(email_regex.match(email)), %{:fileName => "Main.hx", :lineNumber => 160, :className => "Main", :methodName => "regexOperations"})
  end
  def string_formatting() do
    num = 42
    padded = StringTools.lpad(Std.string(num), "0", 5)
    Log.trace("Padded number: " <> padded, %{:fileName => "Main.hx", :lineNumber => 168, :className => "Main", :methodName => "stringFormatting"})
    text = "Hi"
    rpadded = StringTools.rpad(text, " ", 10) <> "|"
    Log.trace("Right padded: " <> rpadded, %{:fileName => "Main.hx", :lineNumber => 172, :className => "Main", :methodName => "stringFormatting"})
    hex = StringTools.hex(255)
    Log.trace("255 in hex: " <> hex, %{:fileName => "Main.hx", :lineNumber => 176, :className => "Main", :methodName => "stringFormatting"})
    url = "Hello World!"
    encoded = StringTools.url_encode(url)
    Log.trace("URL encoded: " <> encoded, %{:fileName => "Main.hx", :lineNumber => 181, :className => "Main", :methodName => "stringFormatting"})
    decoded = StringTools.url_decode(encoded)
    Log.trace("URL decoded: " <> decoded, %{:fileName => "Main.hx", :lineNumber => 183, :className => "Main", :methodName => "stringFormatting"})
  end
  def unicode_strings() do
    unicode = "Hello 世界 🌍"
    Log.trace("Unicode string: " <> unicode, %{:fileName => "Main.hx", :lineNumber => 189, :className => "Main", :methodName => "unicodeStrings"})
    Log.trace("Length: " <> unicode.length, %{:fileName => "Main.hx", :lineNumber => 190, :className => "Main", :methodName => "unicodeStrings"})
    escaped = "Line 1\nLine 2\tTabbed\r\nLine 3"
    Log.trace("Escaped: " <> escaped, %{:fileName => "Main.hx", :lineNumber => 194, :className => "Main", :methodName => "unicodeStrings"})
    quote = "She said \"Hello\""
    Log.trace("Quote: " <> quote, %{:fileName => "Main.hx", :lineNumber => 197, :className => "Main", :methodName => "unicodeStrings"})
    backslash = "Path: C:\\Users\\Name"
    Log.trace("Backslash: " <> backslash, %{:fileName => "Main.hx", :lineNumber => 200, :className => "Main", :methodName => "unicodeStrings"})
  end
  def main() do
    Log.trace("=== String Basics ===", %{:fileName => "Main.hx", :lineNumber => 204, :className => "Main", :methodName => "main"})
    string_basics()
    Log.trace("\n=== String Interpolation ===", %{:fileName => "Main.hx", :lineNumber => 207, :className => "Main", :methodName => "main"})
    string_interpolation()
    Log.trace("\n=== String Methods ===", %{:fileName => "Main.hx", :lineNumber => 210, :className => "Main", :methodName => "main"})
    string_methods()
    Log.trace("\n=== String Comparison ===", %{:fileName => "Main.hx", :lineNumber => 213, :className => "Main", :methodName => "main"})
    string_comparison()
    Log.trace("\n=== String Building ===", %{:fileName => "Main.hx", :lineNumber => 216, :className => "Main", :methodName => "main"})
    string_building()
    Log.trace("\n=== Regex Operations ===", %{:fileName => "Main.hx", :lineNumber => 219, :className => "Main", :methodName => "main"})
    regex_operations()
    Log.trace("\n=== String Formatting ===", %{:fileName => "Main.hx", :lineNumber => 222, :className => "Main", :methodName => "main"})
    string_formatting()
    Log.trace("\n=== Unicode Strings ===", %{:fileName => "Main.hx", :lineNumber => 225, :className => "Main", :methodName => "main"})
    unicode_strings()
  end
end