defmodule Main do
  def string_basics() do
    str1 = "Hello"
    str2 = "World"
    str3 = "#{(fn -> str1 end).()} #{(fn -> str2 end).()}"
    multiline = "This is\na multi-line\nstring"
    nil
  end
  def string_interpolation() do
    name = "Alice"
    age = 30
    pi = 3.14159
    person_name = "Bob"
    person_age = 25
    _ = "apple"
    _ = "banana"
    _ = "orange"
    nil
  end
  def string_methods() do
    str = "  Hello, World!  "
    text = "Hello, World!"
    parts = if (", " == "") do
      String.graphemes(text)
    else
      String.split(text, ", ")
    end
    joined = Enum.join(parts, " - ")
    replaced = StringTools.replace(text, "World", "Haxe")
    nil
  end
  def string_comparison() do
    str1 = "apple"
    str2 = "Apple"
    _ = "apple"
    str4 = "banana"
    if (str1 < str4), do: nil
    if (String.downcase(str1) == String.downcase(str2)), do: nil
  end
  def string_building() do
    buf = %StringBuf{}
    _ = StringBuf.add(buf, "Building ")
    _ = StringBuf.add(buf, "a ")
    _ = StringBuf.add(buf, "string ")
    _ = StringBuf.add(buf, "efficiently")
    _ = StringBuf.add(buf, "!")
    _ = StringBuf.add(buf, "!")
    _ = StringBuf.add(buf, "!")
    result = StringBuf.to_string(buf)
    parts = []
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(1) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(2) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(3) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(4) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(5) end).()}"]
    list = Enum.join(parts, ", ")
    nil
  end
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"
    digit_regex = EReg.new("\\d+", "")
    if (EReg.match(digit_regex, text)), do: nil
    all_numbers = EReg.new("\\d+", "g")
    numbers = []
    temp = text
    {numbers, temp} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[], temp}, fn _, {numbers, temp} ->
      if (EReg.match(all_numbers, temp)) do
        numbers = numbers ++ [EReg.matched(all_numbers, 0)]
        temp = EReg.matched_right(all_numbers)
        {:cont, {numbers, temp}}
      else
        {:halt, {numbers, temp}}
      end
    end)
    nil
    replaced = EReg.replace(EReg.new("\\d+", ""), text, "XXX")
    email = "user@example.com"
    email_regex = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
    nil
  end
  def string_formatting() do
    num = 42
    padded = StringTools.lpad(inspect(num), "0", 5)
    text = "Hi"
    rpadded = "#{(fn -> StringTools.rpad(text, " ", 10) end).()}|"
    hex = StringTools.hex(255)
    url = "Hello World!"
    encoded = StringTools.url_encode(url)
    decoded = StringTools.url_decode(encoded)
    nil
  end
  def unicode_strings() do
    unicode = "Hello 世界 🌍"
    escaped = "Line 1\nLine 2\tTabbed\r\nLine 3"
    quote_ = "She said \"Hello\""
    backslash = "Path: C:\\Users\\Name"
    nil
  end
  def main() do
    _ = string_basics()
    _ = string_interpolation()
    _ = string_methods()
    _ = string_comparison()
    _ = string_building()
    _ = regex_operations()
    _ = string_formatting()
    _ = unicode_strings()
  end
end
