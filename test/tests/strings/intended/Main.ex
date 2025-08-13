defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * String operations test case
 * Tests string manipulation, interpolation, and methods
 
  """

  # Static functions
  @doc "Function string_basics"
  @spec string_basics() :: nil
  def string_basics() do
    (
  str1 = "Hello"
  str2 = "World"
  str3 = str1 + " " + str2
  Log.trace(str3, %{fileName: "Main.hx", lineNumber: 15, className: "Main", methodName: "stringBasics"})
  multiline = "This is
a multi-line
string"
  Log.trace(multiline, %{fileName: "Main.hx", lineNumber: 21, className: "Main", methodName: "stringBasics"})
  Log.trace("Length of "" + str3 + "": " + str3.length, %{fileName: "Main.hx", lineNumber: 24, className: "Main", methodName: "stringBasics"})
)
  end

  @doc "Function string_interpolation"
  @spec string_interpolation() :: nil
  def string_interpolation() do
    (
  name = "Alice"
  age = 30
  pi = 3.14159
  Log.trace("Hello, " + name + "!", %{fileName: "Main.hx", lineNumber: 34, className: "Main", methodName: "stringInterpolation"})
  Log.trace("Age: " + age, %{fileName: "Main.hx", lineNumber: 35, className: "Main", methodName: "stringInterpolation"})
  Log.trace("Next year, " + name + " will be " + (age + 1), %{fileName: "Main.hx", lineNumber: 38, className: "Main", methodName: "stringInterpolation"})
  Log.trace("Pi rounded: " + Math.round(pi * 100) / 100, %{fileName: "Main.hx", lineNumber: 39, className: "Main", methodName: "stringInterpolation"})
  person_name = nil
  person_age = nil
  person_name = "Bob"
  person_age = 25
  Log.trace("Person: " + person_name + " is " + person_age + " years old", %{fileName: "Main.hx", lineNumber: 43, className: "Main", methodName: "stringInterpolation"})
  items = ["apple", "banana", "orange"]
  Log.trace("Items: " + items.join(", "), %{fileName: "Main.hx", lineNumber: 47, className: "Main", methodName: "stringInterpolation"})
  Log.trace("First item: " + Enum.at(items, 0).toUpperCase(), %{fileName: "Main.hx", lineNumber: 48, className: "Main", methodName: "stringInterpolation"})
)
  end

  @doc "Function string_methods"
  @spec string_methods() :: nil
  def string_methods() do
    (
  str = "  Hello, World!  "
  Log.trace("Trimmed: "" + StringTools.trim(str) + """, %{fileName: "Main.hx", lineNumber: 56, className: "Main", methodName: "stringMethods"})
  Log.trace("Upper: " + str.toUpperCase(), %{fileName: "Main.hx", lineNumber: 59, className: "Main", methodName: "stringMethods"})
  Log.trace("Lower: " + str.toLowerCase(), %{fileName: "Main.hx", lineNumber: 60, className: "Main", methodName: "stringMethods"})
  text = "Hello, World!"
  Log.trace("Substring(0, 5): " + text.substring(0, 5), %{fileName: "Main.hx", lineNumber: 64, className: "Main", methodName: "stringMethods"})
  Log.trace("Substr(7, 5): " + text.substr(7, 5), %{fileName: "Main.hx", lineNumber: 65, className: "Main", methodName: "stringMethods"})
  Log.trace("Char at 0: " + text.charAt(0), %{fileName: "Main.hx", lineNumber: 68, className: "Main", methodName: "stringMethods"})
  Log.trace("Char code at 0: " + text.charCodeAt(0), %{fileName: "Main.hx", lineNumber: 69, className: "Main", methodName: "stringMethods"})
  Log.trace("Index of "World": " + text.indexOf("World"), %{fileName: "Main.hx", lineNumber: 72, className: "Main", methodName: "stringMethods"})
  Log.trace("Last index of "o": " + text.lastIndexOf("o"), %{fileName: "Main.hx", lineNumber: 73, className: "Main", methodName: "stringMethods"})
  parts = text.split(", ")
  Log.trace("Split parts: " + Std.string(parts), %{fileName: "Main.hx", lineNumber: 77, className: "Main", methodName: "stringMethods"})
  joined = parts.join(" - ")
  Log.trace("Joined: " + joined, %{fileName: "Main.hx", lineNumber: 79, className: "Main", methodName: "stringMethods"})
  replaced = StringTools.replace(text, "World", "Haxe")
  Log.trace("Replaced: " + replaced, %{fileName: "Main.hx", lineNumber: 83, className: "Main", methodName: "stringMethods"})
)
  end

  @doc "Function string_comparison"
  @spec string_comparison() :: nil
  def string_comparison() do
    (
  str1 = "apple"
  str2 = "Apple"
  str3 = "apple"
  str4 = "banana"
  Log.trace("str1 == str3: " + Std.string(str1 == str3), %{fileName: "Main.hx", lineNumber: 94, className: "Main", methodName: "stringComparison"})
  Log.trace("str1 == str2: " + Std.string(str1 == str2), %{fileName: "Main.hx", lineNumber: 95, className: "Main", methodName: "stringComparison"})
  if (str1 < str4), do: Log.trace("" + str1 + " comes before " + str4, %{fileName: "Main.hx", lineNumber: 99, className: "Main", methodName: "stringComparison"}), else: nil
  if (str1.toLowerCase() == str2.toLowerCase()), do: Log.trace("" + str1 + " and " + str2 + " are equal (case-insensitive)", %{fileName: "Main.hx", lineNumber: 104, className: "Main", methodName: "stringComparison"}), else: nil
)
  end

  @doc "Function string_building"
  @spec string_building() :: nil
  def string_building() do
    (
  buf_b = nil
  buf_b = ""
  buf_b += "Building "
  buf_b += "a "
  buf_b += "string "
  buf_b += "efficiently"
  (
  buf_b += "!"
  buf_b += "!"
  buf_b += "!"
)
  result = buf_b
  Log.trace("Built string: " + result, %{fileName: "Main.hx", lineNumber: 122, className: "Main", methodName: "stringBuilding"})
  parts = []
  (
  parts.push("Item " + 1)
  parts.push("Item " + 2)
  parts.push("Item " + 3)
  parts.push("Item " + 4)
  parts.push("Item " + 5)
)
  list = parts.join(", ")
  Log.trace("List: " + list, %{fileName: "Main.hx", lineNumber: 130, className: "Main", methodName: "stringBuilding"})
)
  end

  @doc "Function regex_operations"
  @spec regex_operations() :: nil
  def regex_operations() do
    (
  text = "The year is 2024 and the time is 15:30"
  digit_regex = EReg.new("\d+", "")
  if (digit_regex.match(text)), do: Log.trace("First number found: " + digit_regex.matched(0), %{fileName: "Main.hx", lineNumber: 140, className: "Main", methodName: "regexOperations"}), else: nil
  all_numbers = EReg.new("\d+", "g")
  numbers = []
  temp = text
  while (all_numbers.match(temp)) do
  (
  numbers.push(all_numbers.matched(0))
  temp = all_numbers.matchedRight()
)
end
  Log.trace("All numbers: " + Std.string(numbers), %{fileName: "Main.hx", lineNumber: 151, className: "Main", methodName: "regexOperations"})
  replaced = EReg.new("\d+", "").replace(text, "XXX")
  Log.trace("Numbers replaced: " + replaced, %{fileName: "Main.hx", lineNumber: 155, className: "Main", methodName: "regexOperations"})
  email = "user@example.com"
  email_regex = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$", "")
  Log.trace("Is valid email: " + Std.string(email_regex.match(email)), %{fileName: "Main.hx", lineNumber: 160, className: "Main", methodName: "regexOperations"})
)
  end

  @doc "Function string_formatting"
  @spec string_formatting() :: nil
  def string_formatting() do
    (
  num = 42
  padded = StringTools.lpad(Std.string(num), "0", 5)
  Log.trace("Padded number: " + padded, %{fileName: "Main.hx", lineNumber: 168, className: "Main", methodName: "stringFormatting"})
  text = "Hi"
  rpadded = StringTools.rpad(text, " ", 10) + "|"
  Log.trace("Right padded: " + rpadded, %{fileName: "Main.hx", lineNumber: 172, className: "Main", methodName: "stringFormatting"})
  hex = StringTools.hex(255)
  Log.trace("255 in hex: " + hex, %{fileName: "Main.hx", lineNumber: 176, className: "Main", methodName: "stringFormatting"})
  url = "Hello World!"
  encoded = nil
  Log.trace("URL encoded: " + encoded, %{fileName: "Main.hx", lineNumber: 181, className: "Main", methodName: "stringFormatting"})
  decoded = nil
  Log.trace("URL decoded: " + decoded, %{fileName: "Main.hx", lineNumber: 183, className: "Main", methodName: "stringFormatting"})
)
  end

  @doc "Function unicode_strings"
  @spec unicode_strings() :: nil
  def unicode_strings() do
    (
  unicode = "Hello 世界 🌍"
  Log.trace("Unicode string: " + unicode, %{fileName: "Main.hx", lineNumber: 189, className: "Main", methodName: "unicodeStrings"})
  Log.trace("Length: " + unicode.length, %{fileName: "Main.hx", lineNumber: 190, className: "Main", methodName: "unicodeStrings"})
  escaped = "Line 1
Line 2	Tabbed
Line 3"
  Log.trace("Escaped: " + escaped, %{fileName: "Main.hx", lineNumber: 194, className: "Main", methodName: "unicodeStrings"})
  quote = "She said "Hello""
  Log.trace("Quote: " + quote, %{fileName: "Main.hx", lineNumber: 197, className: "Main", methodName: "unicodeStrings"})
  backslash = "Path: C:\Users\Name"
  Log.trace("Backslash: " + backslash, %{fileName: "Main.hx", lineNumber: 200, className: "Main", methodName: "unicodeStrings"})
)
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
  Log.trace("=== String Basics ===", %{fileName: "Main.hx", lineNumber: 204, className: "Main", methodName: "main"})
  Main.stringBasics()
  Log.trace("
=== String Interpolation ===", %{fileName: "Main.hx", lineNumber: 207, className: "Main", methodName: "main"})
  Main.stringInterpolation()
  Log.trace("
=== String Methods ===", %{fileName: "Main.hx", lineNumber: 210, className: "Main", methodName: "main"})
  Main.stringMethods()
  Log.trace("
=== String Comparison ===", %{fileName: "Main.hx", lineNumber: 213, className: "Main", methodName: "main"})
  Main.stringComparison()
  Log.trace("
=== String Building ===", %{fileName: "Main.hx", lineNumber: 216, className: "Main", methodName: "main"})
  Main.stringBuilding()
  Log.trace("
=== Regex Operations ===", %{fileName: "Main.hx", lineNumber: 219, className: "Main", methodName: "main"})
  Main.regexOperations()
  Log.trace("
=== String Formatting ===", %{fileName: "Main.hx", lineNumber: 222, className: "Main", methodName: "main"})
  Main.stringFormatting()
  Log.trace("
=== Unicode Strings ===", %{fileName: "Main.hx", lineNumber: 225, className: "Main", methodName: "main"})
  Main.unicodeStrings()
)
  end

end
