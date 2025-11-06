defmodule PatternMatchingTest do
  def match_color(color) do
    (case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, r, g, b} -> "rgb(#{(fn -> r end).()},#{(fn -> g end).()},#{(fn -> b end).()})"
    end)
  end
  def match_option(option) do
    (case option do
      {:none} -> "none"
      {:some, value} ->
        inspect = value
        "some(#{(fn -> inspect(value) end).()})"
    end)
  end
  def match_int(value) do
    (case value do
      0 -> "zero"
      1 -> "one"
      _ ->
        n = value
        if (n < 0) do
          "negative"
        else
          _ = value
          if (value > 100), do: "large", else: "other"
        end
    end)
  end
  def match_string(str) do
    (case str do
      "" -> "empty"
      "hello" -> "greeting"
      _ ->
        s = str
        if (length(s) > 10), do: "long", else: "other"
    end)
  end
  def match_array(arr) do
    (case arr do
      [] -> "empty"
      [_head | _tail] -> "single(#{(fn -> x end).()})"
      2 -> "pair(#{(fn -> x end).()},#{(fn -> y end).()})"
      3 -> "triple(#{(fn -> x end).()},#{(fn -> y end).()},#{(fn -> z end).()})"
      _ -> "many"
    end)
  end
  def match_nested(option) do
    (case option do
      {:none} -> "no color"
      {:some, r} ->
        (case r do
          {:red} -> "red color"
          {:green} -> "green color"
          {:blue} -> "blue color"
          {:rgb, r, _g, _b} when r > 128 -> "bright rgb"
          {:rgb, _r, _g, _b} -> "dark rgb"
        end)
    end)
  end
  def match_bool(flag, count) do
    cond do
      flag ->
        if (count == 0) do
          "true zero"
        else
          n = count
          if (n > 0), do: "true positive", else: "other combination"
        end
      count == 0 -> "false zero"
      :true ->
        n = count
        if (n > 0), do: "false positive", else: "other combination"
    end
  end
  def main() do
    Log.trace("Pattern matching compilation test", %{:file_name => "Main.hx", :line_number => 110, :class_name => "PatternMatchingTest", :method_name => "main"})
  end
end
