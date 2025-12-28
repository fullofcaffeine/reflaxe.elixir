defmodule Main do
  def string_basics() do
    str1 = "Hello"
    str2 = "World"
    _str3 = "#{(fn -> str1 end).()} #{(fn -> str2 end).()}"
    nil
  end
  def string_interpolation() do
    _ = "apple"
    _ = "banana"
    _ = "orange"
    nil
  end
  def string_methods() do
    text = "Hello, World!"
    parts = if (", " == "") do
      String.graphemes(text)
    else
      String.split(text, ", ")
    end
    _joined = Enum.join(parts, " - ")
    _replaced = StringTools.replace(text, "World", "Haxe")
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
    _result = StringBuf.to_string(buf)
    parts = []
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(1) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(2) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(3) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(4) end).()}"]
    parts = parts ++ ["Item #{(fn -> Kernel.to_string(5) end).()}"]
    _list = Enum.join(parts, ", ")
    nil
  end
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"
    digit_regex = EReg.new("\\d+", "")
    if (EReg.match(digit_regex, text)), do: nil
    all_numbers = EReg.new("\\d+", "g")
    numbers = []
    temp = text
    {_numbers, _temp} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, temp}, fn _, {acc_numbers, acc_temp} ->
      try do
        if (EReg.match(all_numbers, acc_temp)) do
          acc_numbers = acc_numbers ++ [EReg.matched(all_numbers, 0)]
          acc_temp = EReg.matched_right(all_numbers)
          {:cont, {acc_numbers, acc_temp}}
        else
          {:halt, {acc_numbers, acc_temp}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_numbers, acc_temp}}
        :throw, :continue ->
          {:cont, {acc_numbers, acc_temp}}
      end
    end)
    _replaced = EReg.replace(EReg.new("\\d+", ""), text, "XXX")
    _email_regex = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
    nil
  end
  def string_formatting() do
    num = 42
    _padded = StringTools.lpad(inspect(num), "0", 5)
    text = "Hi"
    _rpadded = "#{(fn -> StringTools.rpad(text, " ", 10) end).()}|"
    _hex = StringTools.hex(255, nil)
    url = "Hello World!"
    encoded = StringTools.url_encode(url)
    _decoded = StringTools.url_decode(encoded)
    nil
  end
  def unicode_strings() do
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
