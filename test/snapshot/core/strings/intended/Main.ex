defmodule Main do
  def string_basics() do
    str1 = "Hello"
    str2 = "World"
    str3 = "#{(fn -> str1 end).()} #{(fn -> str2 end).()}"
    Log.trace(str3, %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "stringBasics"})
    multiline = "This is\na multi-line\nstring"
    Log.trace(multiline, %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "stringBasics"})
    Log.trace("Length of \"#{(fn -> str3 end).()}\": #{(fn -> length(str3) end).()}", %{:file_name => "Main.hx", :line_number => 24, :class_name => "Main", :method_name => "stringBasics"})
  end
  def string_interpolation() do
    name = "Alice"
    age = 30
    pi = 3.14159
    Log.trace("Hello, #{(fn -> name end).()}!", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Age: #{(fn -> age end).()}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Next year, #{(fn -> name end).()} will be #{(fn -> age + 1 end).()}", %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Pi rounded: #{(fn -> round(pi * 100) / 100 end).()}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "stringInterpolation"})
    person_name = "Bob"
    person_age = 25
    Log.trace("Person: #{(fn -> person_name end).()} is #{(fn -> person_age end).()} years old", %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "stringInterpolation"})
    items = ["apple", "banana", "orange"]
    Log.trace("Items: #{(fn -> Enum.join((fn -> items end).(), ", ") end).()}", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("First item: #{(fn -> String.upcase(items[0]) end).()}", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "stringInterpolation"})
  end
  def string_methods() do
    str = "  Hello, World!  "
    Log.trace("Trimmed: \"#{(fn -> StringTools.ltrim(StringTools.rtrim(str)) end).()}\"", %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Upper: #{(fn -> String.upcase(str) end).()}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Lower: #{(fn -> String.downcase(str) end).()}", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "stringMethods"})
    text = "Hello, World!"
    Log.trace((
"Substring(0, 5): #{(fn -> len = 5
String.slice(text, 0, len) end).()}"
), %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Substr(7, 5): #{(fn -> String.slice(text, 7, 5) end).()}", %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Char at 0: #{(fn -> String.at(text, 0) || "" end).()}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace((
"Char code at 0: #{(fn -> result = :binary.at(text, 0)
if result == nil, do: nil, else: result end).()}"
), %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Index of \"World\": #{(fn -> case :binary.match(text, "World") do
                {pos, _} -> pos
                :nomatch -> -1
            end end).()}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace((
"Last index of \"o\": #{(fn -> start_index = nil
if (start_index == nil) do
  start_index = length(text)
end
sub = String.slice(text, 0, start_index)
case String.split(sub, "o") do
            parts when length(parts) > 1 ->
                String.length(Enum.join(Enum.slice(parts, 0..-2), "o"))
            _ -> -1
        end end).()}"
), %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "stringMethods"})
    parts = String.split(text, ", ")
    Log.trace("Split parts: #{(fn -> inspect(parts) end).()}", %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "stringMethods"})
    joined = Enum.join((fn -> " - " end).())
    Log.trace("Joined: #{(fn -> joined end).()}", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "stringMethods"})
    replaced = StringTools.replace(text, "World", "Haxe")
    Log.trace("Replaced: #{(fn -> replaced end).()}", %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "stringMethods"})
  end
  def string_comparison() do
    str1 = "apple"
    str2 = "Apple"
    str3 = "apple"
    str4 = "banana"
    Log.trace("str1 == str3: #{(fn -> inspect(str1 == str3) end).()}", %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "stringComparison"})
    Log.trace("str1 == str2: #{(fn -> inspect(str1 == str2) end).()}", %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "stringComparison"})
    if (str1 < str4) do
      Log.trace("#{(fn -> str1 end).()} comes before #{(fn -> str4 end).()}", %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "stringComparison"})
    end
    if (String.downcase(str1) == String.downcase(str2)) do
      Log.trace("#{(fn -> str1 end).()} and #{(fn -> str2 end).()} are equal (case-insensitive)", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "stringComparison"})
    end
  end
  def string_building() do
    buf = MyApp.StringBuf.new()
    MyApp.StringBuf.add(buf, "Building ")
    MyApp.StringBuf.add(buf, "a ")
    MyApp.StringBuf.add(buf, "string ")
    MyApp.StringBuf.add(buf, "efficiently")
    MyApp.StringBuf.add(buf, "!")
    MyApp.StringBuf.add(buf, "!")
    MyApp.StringBuf.add(buf, "!")
    result = MyApp.StringBuf.to_string(buf)
    Log.trace("Built string: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 122, :class_name => "Main", :method_name => "stringBuilding"})
    parts = []
    parts = parts ++ ["Item #{(fn -> 1 end).()}"]
    parts = parts ++ ["Item #{(fn -> 2 end).()}"]
    parts = parts ++ ["Item #{(fn -> 3 end).()}"]
    parts = parts ++ ["Item #{(fn -> 4 end).()}"]
    parts = parts ++ ["Item #{(fn -> 5 end).()}"]
    list = Enum.join((fn -> ", " end).())
    Log.trace("List: #{(fn -> list end).()}", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "stringBuilding"})
  end
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"
    digit_regex = MyApp.EReg.new("\\d+", "")
    if (digit_regex.match(text)) do
      Log.trace("First number found: #{(fn -> digit_regex.matched(0) end).()}", %{:file_name => "Main.hx", :line_number => 140, :class_name => "Main", :method_name => "regexOperations"})
    end
    all_numbers = MyApp.EReg.new("\\d+", "g")
    numbers = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {text, all_numbers}, fn _, {text, all_numbers} ->
      if (all_numbers.match(text)) do
        numbers = Enum.concat(numbers, [all_numbers.matched(0)])
        text = all_numbers.matchedRight()
        {:cont, {text, all_numbers}}
      else
        {:halt, {text, all_numbers}}
      end
    end)
    Log.trace("All numbers: #{(fn -> inspect(numbers) end).()}", %{:file_name => "Main.hx", :line_number => 151, :class_name => "Main", :method_name => "regexOperations"})
    replaced = MyApp.EReg.new("\\d+", "").replace(text, "XXX")
    Log.trace("Numbers replaced: #{(fn -> replaced end).()}", %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "regexOperations"})
    email = "user@example.com"
    _ = MyApp.EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
    Log.trace("Is valid email: #{(fn -> inspect(email_regex.match(email)) end).()}", %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "regexOperations"})
  end
  def string_formatting() do
    num = 42
    padded = StringTools.lpad(inspect(num), "0", 5)
    Log.trace("Padded number: #{(fn -> padded end).()}", %{:file_name => "Main.hx", :line_number => 168, :class_name => "Main", :method_name => "stringFormatting"})
    text = "Hi"
    rpadded = "#{(fn -> StringTools.rpad(text, " ", 10) end).()}|"
    Log.trace("Right padded: #{(fn -> rpadded end).()}", %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "stringFormatting"})
    hex = StringTools.hex(255)
    Log.trace("255 in hex: #{(fn -> hex end).()}", %{:file_name => "Main.hx", :line_number => 176, :class_name => "Main", :method_name => "stringFormatting"})
    url = "Hello World!"
    encoded = StringTools.url_encode(url)
    Log.trace("URL encoded: #{(fn -> encoded end).()}", %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "stringFormatting"})
    decoded = StringTools.url_decode(encoded)
    Log.trace("URL decoded: #{(fn -> decoded end).()}", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "stringFormatting"})
  end
  def unicode_strings() do
    unicode = "Hello 世界 🌍"
    Log.trace("Unicode string: #{(fn -> unicode end).()}", %{:file_name => "Main.hx", :line_number => 189, :class_name => "Main", :method_name => "unicodeStrings"})
    Log.trace("Length: #{(fn -> length(unicode) end).()}", %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "unicodeStrings"})
    escaped = "Line 1\nLine 2\tTabbed\r\nLine 3"
    Log.trace("Escaped: #{(fn -> escaped end).()}", %{:file_name => "Main.hx", :line_number => 194, :class_name => "Main", :method_name => "unicodeStrings"})
    quote_ = "She said \"Hello\""
    Log.trace("Quote: #{(fn -> quote_ end).()}", %{:file_name => "Main.hx", :line_number => 197, :class_name => "Main", :method_name => "unicodeStrings"})
    backslash = "Path: C:\\Users\\Name"
    Log.trace("Backslash: #{(fn -> backslash end).()}", %{:file_name => "Main.hx", :line_number => 200, :class_name => "Main", :method_name => "unicodeStrings"})
  end
  def main() do
    Log.trace("=== String Basics ===", %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "main"})
    string_basics()
    Log.trace("\n=== String Interpolation ===", %{:file_name => "Main.hx", :line_number => 207, :class_name => "Main", :method_name => "main"})
    string_interpolation()
    Log.trace("\n=== String Methods ===", %{:file_name => "Main.hx", :line_number => 210, :class_name => "Main", :method_name => "main"})
    string_methods()
    Log.trace("\n=== String Comparison ===", %{:file_name => "Main.hx", :line_number => 213, :class_name => "Main", :method_name => "main"})
    string_comparison()
    Log.trace("\n=== String Building ===", %{:file_name => "Main.hx", :line_number => 216, :class_name => "Main", :method_name => "main"})
    string_building()
    Log.trace("\n=== Regex Operations ===", %{:file_name => "Main.hx", :line_number => 219, :class_name => "Main", :method_name => "main"})
    regex_operations()
    Log.trace("\n=== String Formatting ===", %{:file_name => "Main.hx", :line_number => 222, :class_name => "Main", :method_name => "main"})
    string_formatting()
    Log.trace("\n=== Unicode Strings ===", %{:file_name => "Main.hx", :line_number => 225, :class_name => "Main", :method_name => "main"})
    unicode_strings()
  end
end
