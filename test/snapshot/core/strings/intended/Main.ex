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
    _ = nil
    _ = nil
    person_name = "Bob"
    person_age = 25
    _ = nil
    _ = nil
    _ = nil
    _ = "apple"
    _ = "banana"
    _ = "orange"
    nil
  end
  def string_methods() do
    str = "  Hello, World!  "
    text = "Hello, World!"
    parts = String.split(text, ", ")
    joined = Enum.join((fn -> " - " end).())
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
    _ = parts ++ ["Item #{(fn -> Kernel.to_string(1) end).()}"]
    _ = parts ++ ["Item #{(fn -> Kernel.to_string(2) end).()}"]
    _ = parts ++ ["Item #{(fn -> Kernel.to_string(3) end).()}"]
    _ = parts ++ ["Item #{(fn -> Kernel.to_string(4) end).()}"]
    _ = parts ++ ["Item #{(fn -> Kernel.to_string(5) end).()}"]
    list = Enum.join((fn -> ", " end).())
    nil
  end
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"
    digit_regex = MyApp.EReg.new("\\d+", "")
    if (digit_regex.match(text)), do: nil
    all_numbers = MyApp.EReg.new("\\d+", "g")
    numbers = []
    temp = text
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, temp}, (fn -> fn _, {numbers, temp} ->
      if (all_numbers.match(temp)) do
        _ = numbers ++ [all_numbers.matched(0)]
        temp = all_numbers.matchedRight()
        {:cont, {numbers, temp}}
      else
        {:halt, {numbers, temp}}
      end
    end end).())
    nil
    replaced = MyApp.EReg.new("\\d+", "").replace(text, "XXX")
    email = "user@example.com"
    email_regex = MyApp.EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
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
