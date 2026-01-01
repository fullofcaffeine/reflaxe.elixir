defmodule PatternMatchingTest do
  def match_color(color) do
    (case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, r, _g, b} -> "rgb(#{Kernel.to_string(r)},#{Kernel.to_string(_g)},#{Kernel.to_string(b)})"
    end)
  end
  def match_option(option) do
    (case option do
      {:none} -> "none"
      {:some, value} -> "some(#{inspect(value)})"
    end)
  end
  def match_int(value) do
    (case value do
      0 -> "zero"
      1 -> "one"
      n ->
        n = value
        if (n < 0) do
          "negative"
        else
          n = value
          if (n > 100), do: "large", else: "other"
        end
    end)
  end
  def match_string(str) do
    (case str do
      "" -> "empty"
      "hello" -> "greeting"
      s ->
        s = str
        if (String.length(s) > 10), do: "long", else: "other"
    end)
  end
  def match_array(arr) do
    (case arr do
      [] -> "empty"
      [_head | _tail] ->
        x = arr[0]
        "single(#{Kernel.to_string(x)})"
      2 ->
        x = arr[0]
        y = arr[1]
        "pair(#{Kernel.to_string(x)},#{Kernel.to_string(y)})"
      3 ->
        x = arr[0]
        y = arr[1]
        z = arr[2]
        "triple(#{Kernel.to_string(x)},#{Kernel.to_string(y)},#{Kernel.to_string(z)})"
      _ -> "many"
    end)
  end
  def match_nested(option) do
    (case option do
      {:none} -> "no color"
      {:some, value} ->
        (case value do
          {:red} -> "red color"
          {:green} -> "green color"
          {:blue} -> "blue color"
          {:rgb, r, _g, _b} ->
            if (r > 128), do: "bright rgb", else: "dark rgb"
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
    nil
  end
end
