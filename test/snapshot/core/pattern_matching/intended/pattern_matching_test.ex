defmodule PatternMatchingTest do
  def match_color(color) do
    case (elem(color, 0)) do
      0 ->
        "red"
      1 ->
        "green"
      2 ->
        "blue"
      3 ->
        g = elem(color, 1)
        g1 = elem(color, 2)
        g2 = elem(color, 3)
        r = g
        g = g1
        b = g2
        "rgb(" <> r <> "," <> g <> "," <> b <> ")"
    end
  end
  def match_option(option) do
    case (elem(option, 0)) do
      0 ->
        "none"
      1 ->
        g = elem(option, 1)
        value = g
        "some(" <> Std.string(value) <> ")"
    end
  end
  def match_int(value) do
    case (value) do
      0 ->
        "zero"
      1 ->
        "one"
      _ ->
        n = value
        if (n < 0) do
          "negative"
        else
          n = value
          if (n > 100), do: "large", else: "other"
        end
    end
  end
  def match_string(str) do
    case (str) do
      "" ->
        "empty"
      "hello" ->
        "greeting"
      _ ->
        s = str
        if (s.length > 10), do: "long", else: "other"
    end
  end
  def match_array(arr) do
    case (arr.length) do
      0 ->
        "empty"
      1 ->
        g = arr[0]
        x = g
        "single(" <> x <> ")"
      2 ->
        g = arr[0]
        g1 = arr[1]
        x = g
        y = g1
        "pair(" <> x <> "," <> y <> ")"
      3 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        x = g
        y = g1
        z = g2
        "triple(" <> x <> "," <> y <> "," <> z <> ")"
      _ ->
        "many"
    end
  end
  def match_nested(option) do
    case (elem(option, 0)) do
      0 ->
        "no color"
      1 ->
        g = elem(option, 1)
        case (elem(g, 0)) do
          0 ->
            "red color"
          1 ->
            "green color"
          2 ->
            "blue color"
          3 ->
            g1 = elem(g, 1)
            g2 = elem(g, 2)
            g = elem(g, 3)
            r = g1
            _g = g2
            _b = g
            if (r > 128) do
              "bright rgb"
            else
              _r = g1
              _g = g2
              _b = g
              "dark rgb"
            end
        end
    end
  end
  def match_bool(flag, count) do
    if flag do
      if (count == 0) do
        "true zero"
      else
        n = count
        if (n > 0), do: "true positive", else: "other combination"
      end
    else
      if (count == 0) do
        "false zero"
      else
        n = count
        if (n > 0), do: "false positive", else: "other combination"
      end
    end
  end
  def main() do
    Log.trace("Pattern matching compilation test", %{:fileName => "Main.hx", :lineNumber => 110, :className => "PatternMatchingTest", :methodName => "main"})
  end
end