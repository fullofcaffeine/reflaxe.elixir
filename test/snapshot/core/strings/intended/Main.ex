defmodule Main do
  def string_basics() do
    str1 = "Hello"
    str2 = "World"
    str3 = "#{str1} #{str2}"
    Log.trace(str3, %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "stringBasics"})

    multiline = "This is\na multi-line\nstring"
    Log.trace(multiline, %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "stringBasics"})

    Log.trace("Length of \"#{str3}\": #{String.length(str3)}", %{:file_name => "Main.hx", :line_number => 24, :class_name => "Main", :method_name => "stringBasics"})
  end

  def string_interpolation() do
    name = "Alice"
    age = 30
    pi = 3.14159

    Log.trace("Hello, #{name}!", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Age: #{age}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Next year, #{name} will be #{age + 1}", %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("Pi rounded: #{Float.round(pi, 2)}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "stringInterpolation"})

    person_name = "Bob"
    person_age = 25
    Log.trace("Person: #{person_name} is #{person_age} years old", %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "stringInterpolation"})

    items = ["apple", "banana", "orange"]
    Log.trace("Items: #{Enum.join(items, ", ")}", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "stringInterpolation"})
    Log.trace("First item: #{String.upcase(Enum.at(items, 0))}", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "stringInterpolation"})
  end

  def string_methods() do
    str = "  Hello, World!  "

    Log.trace("Trimmed: \"#{String.trim(str)}\"", %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Upper: #{String.upcase(str)}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Lower: #{String.downcase(str)}", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "stringMethods"})

    text = "Hello, World!"
    Log.trace("Substring(0, 5): #{String.slice(text, 0, 5)}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Substr(7, 5): #{String.slice(text, 7, 5)}", %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "stringMethods"})

    Log.trace("Char at 0: #{String.at(text, 0)}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Char code at 0: #{:binary.first(text)}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "stringMethods"})

    index = case :binary.match(text, "World") do
      {pos, _} -> pos
      nil -> -1
    end
    Log.trace("Index of \"World\": #{index}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "stringMethods"})
    Log.trace("Last index of \"o\": #{String.length(text) - String.length(String.reverse(text) |> String.split("o", parts: 2) |> List.first())}", %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "stringMethods"})

    parts = String.split(text, ", ")
    Log.trace("Split parts: #{inspect(parts)}", %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "stringMethods"})

    joined = Enum.join(parts, " - ")
    Log.trace("Joined: #{joined}", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "stringMethods"})

    replaced = String.replace(text, "World", "Haxe")
    Log.trace("Replaced: #{replaced}", %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "stringMethods"})
  end

  def string_comparison() do
    str1 = "apple"
    str2 = "Apple"
    str3 = "apple"
    str4 = "banana"

    Log.trace("str1 == str3: #{str1 == str3}", %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "stringComparison"})
    Log.trace("str1 == str2: #{str1 == str2}", %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "stringComparison"})

    if str1 < str4 do
      Log.trace("#{str1} comes before #{str4}", %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "stringComparison"})
    end

    if String.downcase(str1) == String.downcase(str2) do
      Log.trace("#{str1} and #{str2} are equal (case-insensitive)", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "stringComparison"})
    end
  end

  def string_building() do
    # Using iolist for efficient string building
    buf = []
    buf = buf ++ ["Building "]
    buf = buf ++ ["a "]
    buf = buf ++ ["string "]
    buf = buf ++ ["efficiently"]
    buf = buf ++ ["!"]
    buf = buf ++ ["!"]
    buf = buf ++ ["!"]
    result = IO.iodata_to_binary(buf)
    Log.trace("Built string: #{result}", %{:file_name => "Main.hx", :line_number => 122, :class_name => "Main", :method_name => "stringBuilding"})

    # Building a list
    parts = for i <- 1..5, do: "Item #{i}"
    list = Enum.join(parts, ", ")
    Log.trace("List: #{list}", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "stringBuilding"})
  end

  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"

    # Find first number
    case Regex.run(~r/\d+/, text) do
      [match | _] -> Log.trace("First number found: #{match}", %{:file_name => "Main.hx", :line_number => 140, :class_name => "Main", :method_name => "regexOperations"})
      _ -> nil
    end

    # Find all numbers
    numbers = Regex.scan(~r/\d+/, text) |> Enum.map(&List.first/1)
    Log.trace("All numbers: #{inspect(numbers)}", %{:file_name => "Main.hx", :line_number => 151, :class_name => "Main", :method_name => "regexOperations"})

    # Replace numbers
    replaced = Regex.replace(~r/\d+/, text, "XXX")
    Log.trace("Numbers replaced: #{replaced}", %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "regexOperations"})

    # Email validation
    email = "user@example.com"
    email_regex = ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
    Log.trace("Is valid email: #{Regex.match?(email_regex, email)}", %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "regexOperations"})
  end

  def string_formatting() do
    num = 42
    padded = String.pad_leading(to_string(num), 5, "0")
    Log.trace("Padded number: #{padded}", %{:file_name => "Main.hx", :line_number => 168, :class_name => "Main", :method_name => "stringFormatting"})

    text = "Hi"
    rpadded = "#{String.pad_trailing(text, 10)}|"
    Log.trace("Right padded: #{rpadded}", %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "stringFormatting"})

    hex = Integer.to_string(255, 16)
    Log.trace("255 in hex: #{hex}", %{:file_name => "Main.hx", :line_number => 176, :class_name => "Main", :method_name => "stringFormatting"})

    url = "Hello World!"
    encoded = URI.encode(url)
    Log.trace("URL encoded: #{encoded}", %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "stringFormatting"})

    decoded = URI.decode(encoded)
    Log.trace("URL decoded: #{decoded}", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "stringFormatting"})
  end

  def unicode_strings() do
    unicode = "Hello 世界 🌍"
    Log.trace("Unicode string: #{unicode}", %{:file_name => "Main.hx", :line_number => 189, :class_name => "Main", :method_name => "unicodeStrings"})
    Log.trace("Length: #{String.length(unicode)}", %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "unicodeStrings"})

    escaped = "Line 1\nLine 2\tTabbed\r\nLine 3"
    Log.trace("Escaped: #{escaped}", %{:file_name => "Main.hx", :line_number => 194, :class_name => "Main", :method_name => "unicodeStrings"})

    quote_param = "She said \"Hello\""
    Log.trace("Quote: #{quote_param}", %{:file_name => "Main.hx", :line_number => 197, :class_name => "Main", :method_name => "unicodeStrings"})

    backslash = "Path: C:\\Users\\Name"
    Log.trace("Backslash: #{backslash}", %{:file_name => "Main.hx", :line_number => 200, :class_name => "Main", :method_name => "unicodeStrings"})
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