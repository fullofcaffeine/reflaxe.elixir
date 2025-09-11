defmodule PatternMatchingTest do
  def match_color(_color) do
    case (_color) do
      {:red} ->
        "red"
      {:green} ->
        "green"
      {:blue} ->
        "blue"
      {:rgb, r, g, b} ->
        g = elem(_color, 1)
        g1 = elem(_color, 2)
        g2 = elem(_color, 3)
        r = g
        g = g1
        b = g2
        "rgb(" <> Kernel.to_string(r) <> "," <> Kernel.to_string(g) <> "," <> Kernel.to_string(b) <> ")"
    end
  end
  def match_option(_option) do
    case (_option) do
      {:none} ->
        "none"
      {:some, value} ->
        g = elem(_option, 1)
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
        if (length(s) > 10), do: "long", else: "other"
    end
  end
  def match_array(arr) do
    case (length(arr)) do
      0 ->
        "empty"
      1 ->
        g = arr[0]
        x = g
        "single(" <> Kernel.to_string(x) <> ")"
      2 ->
        g = arr[0]
        g1 = arr[1]
        x = g
        y = g1
        "pair(" <> Kernel.to_string(x) <> "," <> Kernel.to_string(y) <> ")"
      3 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        x = g
        y = g1
        z = g2
        "triple(" <> Kernel.to_string(x) <> "," <> Kernel.to_string(y) <> "," <> Kernel.to_string(z) <> ")"
      _ ->
        "many"
    end
  end
  def match_nested(_option) do
    case (_option) do
      {:none} ->
        "no color"
      {:some, value} ->
        g = elem(_option, 1)
        case (g) do
          {:red} ->
            "red color"
          {:green} ->
            "green color"
          {:blue} ->
            "blue color"
          {:rgb, r, g, b} ->
            g1 = elem(g, 1)
            g2 = elem(g, 2)
            g = elem(g, 3)
            r = g1
            g = g2
            b = g
            if (r > 128) do
              "bright rgb"
            else
              r = g1
              g = g2
              b = g
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
    Log.trace("Pattern matching compilation test", %{:file_name => "Main.hx", :line_number => 110, :class_name => "PatternMatchingTest", :method_name => "main"})
  end
end