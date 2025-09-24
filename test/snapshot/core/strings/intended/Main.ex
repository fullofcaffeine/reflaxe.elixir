defmodule Main do
  def string_basics() do
    str1 = "Hello"
    str2 = "World"
    str3 = "#{str1} #{str2}"
    Log.trace(str3, %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "stringBasics"})
    multiline = "This is\na multi-line\nstring"
    Log.trace(multiline, %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "stringBasics"})
    Log.trace("Length of \"#{str3}\": #{str3.length}", %{:file_name => "Main.hx", :line_number => 24, :class_name => "Main", :method_name => "stringBasics"})
  end
  def string_interpolation() do
    name = "Alice"
    age = 30
    pi = 3.14159
    Log.trace("Hello, #{name}!", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Age: #{age}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Next year, #{name} will be #{(age + 1)}", %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Pi rounded: #{round(pi * 100) / 100}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "stringInterpolation"})
    person_name = "Bob"
    person_age = 25
    Log.trace("Person: #{person_name} is #{person_age} years old", %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "stringInterpolation"})
    items = ["apple", "banana", "orange"]
    Log.trace("Items: #{Enum.join(items, ", ")}", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("First item: #{String.upcase(items[0])}", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "stringInterpolation"})
  end
  def string_methods() do
    str = "  Hello, World!  "
    Log.trace("Trimmed: \"#{StringTools.ltrim(StringTools.rtrim(str))}\"", %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Upper: #{String.upcase(str)}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Lower: #{String.downcase(str)}", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "stringMethods"})
    text = "Hello, World!"
    Log.trace((
"Substring(0, 5): #{len = 5
String.slice(text, 0, len)}"
), %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Substr(7, 5): #{String.slice(text, 7, 5)}", %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Char at 0: #{String.at(text, 0) || ""}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace((
"Char code at 0: #{result = :binary.at(text, 0)
if result == nil, do: nil, else: result}"
), %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Index of \"World\": #{case :binary.match(text, "World") do
                {pos, _} -> pos
                nil -> -1
            end}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace((
"Last index of \"o\": #{start_index = nil
if (start_index == nil) do
  start_index = text.length
end
sub = String.slice(text, 0, start_index)
case String.split(sub, "o") do
            parts when length(parts) > 1 ->
                String.length(Enum.join(Enum.slice(parts, 0..-2), "o"))
            _ -> -1
        end}"
), %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "stringMethods"})
    parts = String.split(text, ", ")
    Log.trace("Split parts: #{Std.string(parts)}", %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "stringMethods"})
    joined = Enum.join(parts, " - ")
    Log.trace("Joined: #{joined}", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "stringMethods"})
    replaced = StringTools.replace(text, "World", "Haxe")
    Log.trace("Replaced: #{replaced}", %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "stringMethods"})
  end
  def string_comparison() do
    str1 = "apple"
    str2 = "Apple"
    str3 = "apple"
    str4 = "banana"
    Log.trace("str1 == str3: #{Std.string(str1 == str3)}", %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "stringComparison"})
    Log.trace("str1 == str2: #{Std.string(str1 == str2)}", %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "stringComparison"})
    if (str1 < str4) do
      Log.trace("#{str1} comes before #{str4}", %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "stringComparison"})
    end
    if (String.downcase(str1) == String.downcase(str2)) do
      Log.trace("#{str1} and #{str2} are equal (case-insensitive)", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "stringComparison"})
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
    Log.trace("Built string: #{result}", %{:file_name => "Main.hx", :line_number => 122, :class_name => "Main", :method_name => "stringBuilding"})
    parts = []
    parts = parts ++ ["Item #{1}"]
    parts = parts ++ ["Item #{2}"]
    parts = parts ++ ["Item #{3}"]
    parts = parts ++ ["Item #{4}"]
    parts = parts ++ ["Item #{5}"]
    list = Enum.join(parts, ", ")
    Log.trace("List: #{list}", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "stringBuilding"})
  end
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"
    digit_regex = EReg.new("\\d+", "")
    if (digit_regex.match(text)) do
      Log.trace("First number found: #{digit_regex.matched(0)}", %{:file_name => "Main.hx", :line_number => 140, :class_name => "Main", :method_name => "regexOperations"})
    end
    all_numbers = EReg.new("\\d+", "g")
    numbers = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {text, all_numbers, :ok}, fn _, {acc_text, acc_all_numbers, acc_state} -> nil end)
    Log.trace("All numbers: #{Std.string(numbers)}", %{:file_name => "Main.hx", :line_number => 151, :class_name => "Main", :method_name => "regexOperations"})
    replaced = EReg.new("\\d+", "").replace(text, "XXX")
    Log.trace("Numbers replaced: #{replaced}", %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "regexOperations"})
    email = "user@example.com"
    email_regex = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
    Log.trace("Is valid email: #{Std.string(email_regex.match(email))}", %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "regexOperations"})
  end
  def string_formatting() do
    num = 42
    padded = StringTools.lpad(Std.string(num), "0", 5)
    Log.trace("Padded number: #{padded}", %{:file_name => "Main.hx", :line_number => 168, :class_name => "Main", :method_name => "stringFormatting"})
    text = "Hi"
    rpadded = "#{StringTools.rpad(text, " ", 10)}|"
    Log.trace("Right padded: #{rpadded}", %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "stringFormatting"})
    hex = StringTools.hex(255)
    Log.trace("255 in hex: #{hex}", %{:file_name => "Main.hx", :line_number => 176, :class_name => "Main", :method_name => "stringFormatting"})
    url = "Hello World!"
    encoded = StringTools.url_encode(url)
    Log.trace("URL encoded: #{encoded}", %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "stringFormatting"})
    decoded = StringTools.url_decode(encoded)
    Log.trace("URL decoded: #{decoded}", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "stringFormatting"})
  end
  def unicode_strings() do
    unicode = "Hello 世界 🌍"
    Log.trace("Unicode string: #{unicode}", %{:file_name => "Main.hx", :line_number => 189, :class_name => "Main", :method_name => "unicodeStrings"})
    Log.trace("Length: #{unicode.length}", %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "unicodeStrings"})
    escaped = "Line 1\nLine 2\tTabbed\r\nLine 3"
    Log.trace("Escaped: #{escaped}", %{:file_name => "Main.hx", :line_number => 194, :class_name => "Main", :method_name => "unicodeStrings"})
    quote_ = "She said \"Hello\""
    Log.trace("Quote: #{quote_}", %{:file_name => "Main.hx", :line_number => 197, :class_name => "Main", :method_name => "unicodeStrings"})
    backslash = "Path: C:\\Users\\Name"
    Log.trace("Backslash: #{backslash}", %{:file_name => "Main.hx", :line_number => 200, :class_name => "Main", :method_name => "unicodeStrings"})
  end
  def main() do
    Log.trace("=== String Basics ===", %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "main"})
    Main.string_basics()
    Log.trace("\n=== String Interpolation ===", %{:file_name => "Main.hx", :line_number => 207, :class_name => "Main", :method_name => "main"})
    Main.string_interpolation()
    Log.trace("\n=== String Methods ===", %{:file_name => "Main.hx", :line_number => 210, :class_name => "Main", :method_name => "main"})
    Main.string_methods()
    Log.trace("\n=== String Comparison ===", %{:file_name => "Main.hx", :line_number => 213, :class_name => "Main", :method_name => "main"})
    Main.string_comparison()
    Log.trace("\n=== String Building ===", %{:file_name => "Main.hx", :line_number => 216, :class_name => "Main", :method_name => "main"})
    Main.string_building()
    Log.trace("\n=== Regex Operations ===", %{:file_name => "Main.hx", :line_number => 219, :class_name => "Main", :method_name => "main"})
    Main.regex_operations()
    Log.trace("\n=== String Formatting ===", %{:file_name => "Main.hx", :line_number => 222, :class_name => "Main", :method_name => "main"})
    Main.string_formatting()
    Log.trace("\n=== Unicode Strings ===", %{:file_name => "Main.hx", :line_number => 225, :class_name => "Main", :method_name => "main"})
    Main.unicode_strings()
  end
end