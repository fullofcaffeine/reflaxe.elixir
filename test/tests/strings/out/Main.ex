defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * String operations test case
     * Tests string manipulation, interpolation, and methods
  """

  # Static functions
  @doc "Generated from Haxe stringBasics"
  def string_basics() do
    str1 = "Hello"

    str2 = "World"

    str3 = str1 <> " " <> str2

    Log.trace(str3, %{"fileName" => "Main.hx", "lineNumber" => 15, "className" => "Main", "methodName" => "stringBasics"})

    multiline = "This is\na multi-line\nstring"

    Log.trace(multiline, %{"fileName" => "Main.hx", "lineNumber" => 21, "className" => "Main", "methodName" => "stringBasics"})

    Log.trace("Length of \"" <> str3 <> "\": " <> to_string(str3.length), %{"fileName" => "Main.hx", "lineNumber" => 24, "className" => "Main", "methodName" => "stringBasics"})
  end

  @doc "Generated from Haxe stringInterpolation"
  def string_interpolation() do
    name = "Alice"

    age = 30

    pi = 3.14159

    Log.trace("Hello, " <> name <> "!", %{"fileName" => "Main.hx", "lineNumber" => 34, "className" => "Main", "methodName" => "stringInterpolation"})

    Log.trace("Age: " <> to_string(age), %{"fileName" => "Main.hx", "lineNumber" => 35, "className" => "Main", "methodName" => "stringInterpolation"})

    Log.trace("Next year, " <> name <> " will be " <> to_string(((age + 1))), %{"fileName" => "Main.hx", "lineNumber" => 38, "className" => "Main", "methodName" => "stringInterpolation"})

    Log.trace("Pi rounded: " <> to_string((Math.round((pi * 100)) / 100)), %{"fileName" => "Main.hx", "lineNumber" => 39, "className" => "Main", "methodName" => "stringInterpolation"})

    person_name = "Bob"

    person_age = 25

    Log.trace("Person: " <> person_name <> " is " <> to_string(person_age) <> " years old", %{"fileName" => "Main.hx", "lineNumber" => 43, "className" => "Main", "methodName" => "stringInterpolation"})

    items = ["apple", "banana", "orange"]

    Log.trace("Items: " <> Enum.join(items, ", "), %{"fileName" => "Main.hx", "lineNumber" => 47, "className" => "Main", "methodName" => "stringInterpolation"})

    Log.trace("First item: " <> Enum.at(items, 0).to_upper_case(), %{"fileName" => "Main.hx", "lineNumber" => 48, "className" => "Main", "methodName" => "stringInterpolation"})
  end

  @doc "Generated from Haxe stringMethods"
  def string_methods() do
    str = "  Hello, World!  "

    Log.trace("Trimmed: \"" <> StringTools.trim(str) <> "\"", %{"fileName" => "Main.hx", "lineNumber" => 56, "className" => "Main", "methodName" => "stringMethods"})

    Log.trace("Upper: " <> str.to_upper_case(), %{"fileName" => "Main.hx", "lineNumber" => 59, "className" => "Main", "methodName" => "stringMethods"})

    Log.trace("Lower: " <> str.to_lower_case(), %{"fileName" => "Main.hx", "lineNumber" => 60, "className" => "Main", "methodName" => "stringMethods"})

    text = "Hello, World!"

    Log.trace("Substring(0, 5): " <> text.substring(0, 5), %{"fileName" => "Main.hx", "lineNumber" => 64, "className" => "Main", "methodName" => "stringMethods"})

    Log.trace("Substr(7, 5): " <> text.substr(7, 5), %{"fileName" => "Main.hx", "lineNumber" => 65, "className" => "Main", "methodName" => "stringMethods"})

    Log.trace("Char at 0: " <> text.char_at(0), %{"fileName" => "Main.hx", "lineNumber" => 68, "className" => "Main", "methodName" => "stringMethods"})

    Log.trace("Char code at 0: " <> to_string(text.char_code_at(0)), %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "stringMethods"})

    Log.trace("Index of \"World\": " <> to_string(text.index_of("World")), %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "stringMethods"})

    Log.trace("Last index of \"o\": " <> to_string(text.last_index_of("o")), %{"fileName" => "Main.hx", "lineNumber" => 73, "className" => "Main", "methodName" => "stringMethods"})

    parts = text.split(", ")

    Log.trace("Split parts: " <> Std.string(parts), %{"fileName" => "Main.hx", "lineNumber" => 77, "className" => "Main", "methodName" => "stringMethods"})

    joined = Enum.join(parts, " - ")

    Log.trace("Joined: " <> joined, %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "stringMethods"})

    replaced = StringTools.replace(text, "World", "Haxe")

    Log.trace("Replaced: " <> replaced, %{"fileName" => "Main.hx", "lineNumber" => 83, "className" => "Main", "methodName" => "stringMethods"})
  end

  @doc "Generated from Haxe stringComparison"
  def string_comparison() do
    str1 = "apple"

    str2 = "Apple"

    str3 = "apple"

    str4 = "banana"

    Log.trace("str1 == str3: " <> Std.string((str1 == str3)), %{"fileName" => "Main.hx", "lineNumber" => 94, "className" => "Main", "methodName" => "stringComparison"})

    Log.trace("str1 == str2: " <> Std.string((str1 == str2)), %{"fileName" => "Main.hx", "lineNumber" => 95, "className" => "Main", "methodName" => "stringComparison"})

    if ((str1 < str4)), do: Log.trace("" <> str1 <> " comes before " <> str4, %{"fileName" => "Main.hx", "lineNumber" => 99, "className" => "Main", "methodName" => "stringComparison"}), else: nil

    if ((str1.to_lower_case() == str2.to_lower_case())), do: Log.trace("" <> str1 <> " and " <> str2 <> " are equal (case-insensitive)", %{"fileName" => "Main.hx", "lineNumber" => 104, "className" => "Main", "methodName" => "stringComparison"}), else: nil
  end

  @doc "Generated from Haxe stringBuilding"
  def string_building() do
    buf_b = ""

    buf_b = buf_b <> "Building "

    buf_b = buf_b <> "a "

    buf_b = buf_b <> "string "

    buf_b = buf_b <> "efficiently"

    buf_b = buf_b <> "!"

    buf_b = buf_b <> "!"

    buf_b = buf_b <> "!"

    Log.trace("Built string: " <> buf_b, %{"fileName" => "Main.hx", "lineNumber" => 122, "className" => "Main", "methodName" => "stringBuilding"})

    parts = []

    parts = parts ++ ["Item " <> to_string(1)]

    parts = parts ++ ["Item " <> to_string(2)]

    parts = parts ++ ["Item " <> to_string(3)]

    parts = parts ++ ["Item " <> to_string(4)]

    parts = parts ++ ["Item " <> to_string(5)]

    list = Enum.join(parts, ", ")

    Log.trace("List: " <> list, %{"fileName" => "Main.hx", "lineNumber" => 130, "className" => "Main", "methodName" => "stringBuilding"})
  end

  @doc "Generated from Haxe regexOperations"
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"

    digit_regex = EReg.new("\\d+", "")

    if digit_regex.match(text), do: Log.trace("First number found: " <> digit_regex.matched(0), %{"fileName" => "Main.hx", "lineNumber" => 140, "className" => "Main", "methodName" => "regexOperations"}), else: nil

    all_numbers = EReg.new("\\d+", "g")

    numbers = []

    (fn loop ->
      if all_numbers.match(text) do
            numbers = numbers ++ [all_numbers.matched(0)]
        text = all_numbers.matched_right()
        loop.()
      end
    end).()

    Log.trace("All numbers: " <> Std.string(numbers), %{"fileName" => "Main.hx", "lineNumber" => 151, "className" => "Main", "methodName" => "regexOperations"})

    replaced = EReg.new("\\d+", "").replace(text, "XXX")

    Log.trace("Numbers replaced: " <> replaced, %{"fileName" => "Main.hx", "lineNumber" => 155, "className" => "Main", "methodName" => "regexOperations"})

    email = "user@example.com"

    email_regex = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")

    Log.trace("Is valid email: " <> Std.string(email_regex.match(email)), %{"fileName" => "Main.hx", "lineNumber" => 160, "className" => "Main", "methodName" => "regexOperations"})
  end

  @doc "Generated from Haxe stringFormatting"
  def string_formatting() do
    num = 42

    padded = StringTools.lpad(Std.string(num), "0", 5)

    Log.trace("Padded number: " <> padded, %{"fileName" => "Main.hx", "lineNumber" => 168, "className" => "Main", "methodName" => "stringFormatting"})

    text = "Hi"

    rpadded = StringTools.rpad(text, " ", 10) <> "|"

    Log.trace("Right padded: " <> rpadded, %{"fileName" => "Main.hx", "lineNumber" => 172, "className" => "Main", "methodName" => "stringFormatting"})

    hex = StringTools.hex(255)

    Log.trace("255 in hex: " <> hex, %{"fileName" => "Main.hx", "lineNumber" => 176, "className" => "Main", "methodName" => "stringFormatting"})

    _url = "Hello World!"

    encoded = nil

    Log.trace("URL encoded: " <> encoded, %{"fileName" => "Main.hx", "lineNumber" => 181, "className" => "Main", "methodName" => "stringFormatting"})

    decoded = nil

    Log.trace("URL decoded: " <> decoded, %{"fileName" => "Main.hx", "lineNumber" => 183, "className" => "Main", "methodName" => "stringFormatting"})
  end

  @doc "Generated from Haxe unicodeStrings"
  def unicode_strings() do
    unicode = "Hello 世界 🌍"

    Log.trace("Unicode string: " <> unicode, %{"fileName" => "Main.hx", "lineNumber" => 189, "className" => "Main", "methodName" => "unicodeStrings"})

    Log.trace("Length: " <> to_string(unicode.length), %{"fileName" => "Main.hx", "lineNumber" => 190, "className" => "Main", "methodName" => "unicodeStrings"})

    escaped = "Line 1\nLine 2\tTabbed\r\nLine 3"

    Log.trace("Escaped: " <> escaped, %{"fileName" => "Main.hx", "lineNumber" => 194, "className" => "Main", "methodName" => "unicodeStrings"})

    quote_ = "She said \"Hello\""

    Log.trace("Quote: " <> quote_, %{"fileName" => "Main.hx", "lineNumber" => 197, "className" => "Main", "methodName" => "unicodeStrings"})

    backslash = "Path: C:\\Users\\Name"

    Log.trace("Backslash: " <> backslash, %{"fileName" => "Main.hx", "lineNumber" => 200, "className" => "Main", "methodName" => "unicodeStrings"})
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace("=== String Basics ===", %{"fileName" => "Main.hx", "lineNumber" => 204, "className" => "Main", "methodName" => "main"})

    Main.string_basics()

    Log.trace("\n=== String Interpolation ===", %{"fileName" => "Main.hx", "lineNumber" => 207, "className" => "Main", "methodName" => "main"})

    Main.string_interpolation()

    Log.trace("\n=== String Methods ===", %{"fileName" => "Main.hx", "lineNumber" => 210, "className" => "Main", "methodName" => "main"})

    Main.string_methods()

    Log.trace("\n=== String Comparison ===", %{"fileName" => "Main.hx", "lineNumber" => 213, "className" => "Main", "methodName" => "main"})

    Main.string_comparison()

    Log.trace("\n=== String Building ===", %{"fileName" => "Main.hx", "lineNumber" => 216, "className" => "Main", "methodName" => "main"})

    Main.string_building()

    Log.trace("\n=== Regex Operations ===", %{"fileName" => "Main.hx", "lineNumber" => 219, "className" => "Main", "methodName" => "main"})

    Main.regex_operations()

    Log.trace("\n=== String Formatting ===", %{"fileName" => "Main.hx", "lineNumber" => 222, "className" => "Main", "methodName" => "main"})

    Main.string_formatting()

    Log.trace("\n=== Unicode Strings ===", %{"fileName" => "Main.hx", "lineNumber" => 225, "className" => "Main", "methodName" => "main"})

    Main.unicode_strings()
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
