defmodule Main do
  def main() do
    v = nullable_right(nil)
    IO.puts(v)
    v = nullable_right("s")
    IO.puts(v)
    v = nullable_left(nil)
    IO.puts(v)
    v = nullable_left("s")
    IO.puts(v)
    v = nullable_interpolated(nil)
    IO.puts(v)
    v = nullable_interpolated("s")
    IO.puts(v)
    v = nullable_only(nil)
    IO.puts(v)
    v = plain_right("s")
    IO.puts(v)
    v = plain_left("s")
    IO.puts(v)
    v = plain_interpolated("a", "b")
    IO.puts(v)
    v = dynamic_both(nil)
    IO.puts(v)
    v = dynamic_both(7)
    IO.puts(v)
    v = dynamic_interpolated(nil)
    IO.puts(v)
    v = nullable_number(nil)
    IO.puts(v)
    v = nullable_number(3)
    IO.puts(v)
    v = nullable_flag(nil)
    IO.puts(v)
    v = append("log", nil)
    IO.puts(v)
    v = append("log", ":x")
    IO.puts(v)
    v = append_to(nil, "tail")
    IO.puts(v)
    v = field_value(Label.new(nil))
    IO.puts(v)
    v = field_value(Label.new("named"))
    IO.puts(v)
    v = optional(nil)
    IO.puts(v)
    v = optional("given")
    IO.puts(v)
    v = missing_key(%{"k" => "v"}, "other")
    IO.puts(v)
    v = missing_key(%{"k" => "v"}, "k")
    IO.puts(v)
    v = literal_null()
    IO.puts(v)
    v = chain(nil, "b", nil)
    IO.puts(v)
    v = chain("a", "b", 1)
    IO.puts(v)
    v = two_level_alias(nil)
    IO.puts(v)
    v = two_level_alias("v")
    IO.puts(v)
    v = three_level_alias(nil)
    IO.puts(v)
    v = three_level_alias("v")
    IO.puts(v)
    v = alias_of_plain("v")
    IO.puts(v)
    v = non_null(false, 5)
    IO.puts(v)
    v = non_null(true, 6)
    IO.puts(v)
    v = Reflaxe.Elixir.HaxeFloat.to_string(nil)
    IO.puts(v)
    v = std_string(nil)
    IO.puts(v)
    nil
  end
  def nullable_right(value) do
    "x/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def nullable_left(value) do
    "#{Reflaxe.Elixir.HaxeFloat.to_string(value)}/x"
  end
  def nullable_interpolated(value) do
    "x/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def nullable_only(value) do
    "#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def plain_right(value) do
    "x/#{value}"
  end
  def plain_left(value) do
    "#{value}/x"
  end
  def plain_interpolated(first, second) do
    "<#{first}|#{second}>"
  end
  def dynamic_both(value) do
    "x/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}|#{Reflaxe.Elixir.HaxeFloat.to_string(value)}/x"
  end
  def dynamic_interpolated(value) do
    "x/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def nullable_number(value) do
    "n=#{Reflaxe.Elixir.HaxeFloat.to_string(value)}|#{Reflaxe.Elixir.HaxeFloat.to_string(value)}=n"
  end
  def nullable_flag(value) do
    "flag=#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def append(text, suffix) do
    text = "#{text}#{Reflaxe.Elixir.HaxeFloat.to_string(suffix)}"
    text
  end
  def append_to(text, suffix) do
    text = "#{Reflaxe.Elixir.HaxeFloat.to_string(text)}#{suffix}"
    text
  end
  def field_value(label) do
    "name=#{Reflaxe.Elixir.HaxeFloat.to_string(label.name)}"
  end
  def optional(value \\ nil) do
    "optional=#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def missing_key(values, key) do
    "value=#{Reflaxe.Elixir.HaxeFloat.to_string(Map.get(values, key))}"
  end
  def literal_null() do
    "literal=null"
  end
  def chain(first, second, third) do
    "a/#{Reflaxe.Elixir.HaxeFloat.to_string(first)}/#{second}/#{Reflaxe.Elixir.HaxeFloat.to_string(third)}"
  end
  def two_level_alias(value) do
    "a/#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def three_level_alias(value) do
    "#{Reflaxe.Elixir.HaxeFloat.to_string(value)}/c"
  end
  def alias_of_plain(value) do
    "p/#{value}"
  end
  def non_null(flag, count) do
    "count=#{Reflaxe.Elixir.HaxeFloat.to_string(count)}/part#{if (flag), do: "/yes", else: "/no"}"
  end
  def std_string(value) do
    Reflaxe.Elixir.HaxeFloat.to_string(value)
  end
end
