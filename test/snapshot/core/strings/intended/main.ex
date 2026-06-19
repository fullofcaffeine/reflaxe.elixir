defmodule Main do
  def string_basics() do
    str1 = "Hello"
    str2 = "World"
    _str3 = "#{str1} #{str2}"
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
    buf = StringBuf.new()
    buf = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "Building "])
    buf = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "a "])
    buf = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "string "])
    buf = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "efficiently"])
    buf = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "!"])
    buf = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "!"])
    buf = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "!"])
    _result = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :to_string, [buf])
    parts = []
    parts = parts ++ ["Item #{Reflaxe.Elixir.HaxeFloat.to_string(1)}"]
    parts = parts ++ ["Item #{Reflaxe.Elixir.HaxeFloat.to_string(2)}"]
    parts = parts ++ ["Item #{Reflaxe.Elixir.HaxeFloat.to_string(3)}"]
    parts = parts ++ ["Item #{Reflaxe.Elixir.HaxeFloat.to_string(4)}"]
    parts = parts ++ ["Item #{Reflaxe.Elixir.HaxeFloat.to_string(5)}"]
    _list = Enum.join(parts, ", ")
    nil
  end
  def regex_operations() do
    text = "The year is 2024 and the time is 15:30"
    digit_regex = EReg.new("\\d+", "")
    if (apply(Map.get(digit_regex, :__reflaxe_class__) || Map.get(digit_regex, :__struct__), :match, [digit_regex, text])), do: nil
    all_numbers = EReg.new("\\d+", "g")
    numbers = []
    temp = text
    {_numbers, _temp} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, temp}, fn _, {acc_numbers, acc_temp} ->
      try do
        if (apply(Map.get(all_numbers, :__reflaxe_class__) || Map.get(all_numbers, :__struct__), :match, [all_numbers, acc_temp])) do
          acc_numbers = acc_numbers ++ [apply(Map.get(all_numbers, :__reflaxe_class__) || Map.get(all_numbers, :__struct__), :matched, [all_numbers, 0])]
          acc_temp = apply(Map.get(all_numbers, :__reflaxe_class__) || Map.get(all_numbers, :__struct__), :matched_right, [all_numbers])
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
    reflaxe_dispatch_receiver = EReg.new("\\d+", "")
    _replaced = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :replace, [reflaxe_dispatch_receiver, text, "XXX"])
    _email_regex = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
    nil
  end
  def string_formatting() do
    num = 42
    _padded = StringTools.lpad(Reflaxe.Elixir.HaxeFloat.to_string(num), "0", 5)
    text = "Hi"
    _rpadded = "#{StringTools.rpad(text, " ", 10)}|"
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
