defmodule Main do
  def match_simple_value(value) do
    (case value do
      0 -> "zero"
      1 -> "one"
      2 -> "two"
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
  def process_array(arr) do
    (case arr do
      [] -> "empty"
      [_head | _tail] -> "single: #{(fn -> x end).()}"
      2 -> "pair: #{(fn -> x end).()},#{(fn -> y end).()}"
      3 -> "triple: #{(fn -> x end).()},#{(fn -> y end).()},#{(fn -> z end).()}"
      4 -> "quad: #{(fn -> first end).()},#{(fn -> second end).()},#{(fn -> third end).()},#{(fn -> fourth end).()}"
      _ ->
        a = arr
        if (length(a) > 4) do
          "many: #{(fn -> length(a) end).()} elements"
        else
          "unknown"
        end
    end)
  end
  def classify_string(str) do
    (case str do
      "" -> "empty"
      "goodbye" -> "farewell"
      "hello" -> "greeting"
      _ ->
        s = str
        if (length(s) == 1) do
          "single char"
        else
          _ = str
          if (length(s) > 10 and length(s) <= 20) do
            "medium"
          else
            _ = str
            if (length(s) > 20), do: "long", else: "other"
          end
        end
    end)
  end
  def classify_number(n) do
    if (n == 0) do
      "zero"
    else
      x = n
      if (x > 0 and x <= 1) do
        "tiny"
      else
        _ = n
        if (x > 1 and x <= 10) do
          "small"
        else
          _ = n
          if (x > 10 and x <= 100) do
            "medium"
          else
            _ = n
            if (x > 100 and x <= 1000) do
              "large"
            else
              _ = n
              if (x > 1000) do
                "huge"
              else
                _ = n
                if (x < 0 and x >= -10) do
                  "small negative"
                else
                  _ = n
                  if (x < -10), do: "large negative", else: "unknown"
                end
              end
            end
          end
        end
      end
    end
  end
  def match_flags(active, verified, premium) do
    if (active) do
      cond do
        verified ->
          if (premium), do: "full access", else: "verified user"
        premium -> "unverified premium"
        :true -> "basic user"
      end
    else
      "inactive"
    end
  end
  def match_matrix(matrix) do
    (case matrix do
      [] -> "empty matrix"
      [_head | _tail] when length(g) == 1 -> "single element: #{(fn -> x end).()}"
      [_head | _tail] when length(m) == length(_head) -> "square matrix #{(fn -> length(m) end).()}x#{(fn -> length(m) end).()}"
      [_head | _tail] -> "non-square matrix"
      2 ->
        cond do
          length(_g) == 2 ->
            g4 = _g[0]
            g5 = _g[1]
            "2x2 matrix: [[" <> Kernel.to_string(a) <> "," <> Kernel.to_string(b) <> "],[" <> Kernel.to_string(c) <> "," <> Kernel.to_string(d) <> "]]"
          length(m) == length(m[0]) -> "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
          true -> "non-square matrix"
        end
      2 when length(m) == length(m[0]) -> "square matrix #{(fn -> length(m) end).()}x#{(fn -> length(m) end).()}"
      2 -> "non-square matrix"
      3 ->
        cond do
          length(_g) == 3 ->
            g6 = _g[0]
            g7 = _g[1]
            g8 = _g[2]
            if (length(_g) == 3) do
              g9 = _g[0]
              g10 = _g[1]
              g11 = _g[2]
              h = _g10
              i = _g11
              a = _g3
              b = _g4
              c = _g5
              f = _g8
              e = _g7
              d = _g6
              "3x3 matrix"
            else
              if (length(m) == length(m[0])) do
                "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
              else
                "non-square matrix"
              end
            end
          length(m) == length(m[0]) -> "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
          true -> "non-square matrix"
        end
      3 when length(m) == length(m[0]) -> "square matrix #{(fn -> length(m) end).()}x#{(fn -> length(m) end).()}"
      3 -> "non-square matrix"
      _ ->
        m = matrix
        if (length(m) == length(m[0])) do
          "square matrix #{(fn -> length(m) end).()}x#{(fn -> length(m) end).()}"
        else
          "non-square matrix"
        end
    end)
  end
  def validate_age(age, has_permission) do
    a = age
    if (a < 0) do
      "invalid age"
    else
      _ = age
      if (a >= 0 and a < 13) do
        "child"
      else
        (case has_permission do
          :false when age >= 13 and age < 18 -> "teen without permission"
          :false when age >= 18 and age < 21 -> "young adult"
          :false when age >= 21 and age < 65 -> "adult"
          :false when age >= 65 -> "senior"
          :false -> "unknown"
          :true when age >= 13 and age < 18 -> "teen with permission"
          :true when age >= 18 and age < 21 -> "young adult"
          :true when age >= 21 and age < 65 -> "adult"
          :true when age >= 65 -> "senior"
          :true -> "unknown"
          _ ->
            _ = age
            if (a >= 18 and a < 21) do
              "young adult"
            else
              _ = age
              if (a >= 21 and a < 65) do
                "adult"
              else
                _ = age
                if (a >= 65), do: "senior", else: "unknown"
              end
            end
        end)
      end
    end
  end
  def classify_value(value) do
    v = value
    if (MyApp.Std.is(v, String)) do
      "string: \"#{(fn -> inspect(v) end).()}\""
    else
      v = value
      if (MyApp.Std.is(v2, Int)) do
        "integer: #{(fn -> inspect(v2) end).()}"
      else
        v = value
        if (MyApp.Std.is(v3, Float)) do
          "float: #{(fn -> inspect(v3) end).()}"
        else
          v = value
          if (MyApp.Std.is(v4, Bool)) do
            "boolean: #{(fn -> inspect(v4) end).()}"
          else
            v = value
            cond do
              Std.is(v5, Array) -> "array of length " <> inspect(Map.get(v5, :length))
              value == nil -> "null value"
              :true -> "unknown type"
            end
          end
        end
      end
    end
  end
  def check_color(color) do
    primary_colors = ["red", "green", "blue"]
    secondary_colors = ["orange", "purple", "yellow"]
    c = color
    if (
                case Enum.find_index(primary_colors, fn item -> item == c end) do
                    nil -> -1
                    idx -> idx
                end
             >= 0) do
      "primary color"
    else
      c2 = color
      if (
                case Enum.find_index(secondary_colors, fn item -> item == c2 end) do
                    nil -> -1
                    idx -> idx
                end
             >= 0) do
        "secondary color"
      else
        (case color do
          "black" -> "monochrome"
          _ -> "unknown color"
        end)
      end
    end
  end
  def match_status(status) do
    (case status do
      "crashed" -> "error state"
      "disabled" -> "not operational"
      "active" -> "operational"
      "paused" -> "temporarily stopped"
      _ -> "unknown status"
    end)
  end
  def main() do
    _ = Log.trace("Advanced pattern matching test", %{:file_name => "Main.hx", :line_number => 201, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_simple_value(0), %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_simple_value(42), %{:file_name => "Main.hx", :line_number => 205, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_simple_value(-5), %{:file_name => "Main.hx", :line_number => 206, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_simple_value(150), %{:file_name => "Main.hx", :line_number => 207, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_array([]), %{:file_name => "Main.hx", :line_number => 210, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_array([1]), %{:file_name => "Main.hx", :line_number => 211, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_array([1, 2]), %{:file_name => "Main.hx", :line_number => 212, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_array([1, 2, 3]), %{:file_name => "Main.hx", :line_number => 213, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(process_array([1, 2, 3, 4, 5]), %{:file_name => "Main.hx", :line_number => 214, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_string(""), %{:file_name => "Main.hx", :line_number => 217, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_string("hello"), %{:file_name => "Main.hx", :line_number => 218, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_string("x"), %{:file_name => "Main.hx", :line_number => 219, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_string("medium length string"), %{:file_name => "Main.hx", :line_number => 220, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_string("this is a very long string that exceeds twenty characters"), %{:file_name => "Main.hx", :line_number => 221, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(0), %{:file_name => "Main.hx", :line_number => 224, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(0.5), %{:file_name => "Main.hx", :line_number => 225, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(5), %{:file_name => "Main.hx", :line_number => 226, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(50), %{:file_name => "Main.hx", :line_number => 227, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(500), %{:file_name => "Main.hx", :line_number => 228, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(5000), %{:file_name => "Main.hx", :line_number => 229, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(-5), %{:file_name => "Main.hx", :line_number => 230, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_number(-50), %{:file_name => "Main.hx", :line_number => 231, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_flags(true, true, true), %{:file_name => "Main.hx", :line_number => 234, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_flags(true, true, false), %{:file_name => "Main.hx", :line_number => 235, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_flags(false, false, false), %{:file_name => "Main.hx", :line_number => 236, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_matrix([]), %{:file_name => "Main.hx", :line_number => 239, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_matrix([[1]]), %{:file_name => "Main.hx", :line_number => 240, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_matrix([[1, 2], [3, 4]]), %{:file_name => "Main.hx", :line_number => 241, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_matrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]]), %{:file_name => "Main.hx", :line_number => 242, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(validate_age(10, false), %{:file_name => "Main.hx", :line_number => 245, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(validate_age(15, true), %{:file_name => "Main.hx", :line_number => 246, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(validate_age(25, false), %{:file_name => "Main.hx", :line_number => 247, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(validate_age(70, true), %{:file_name => "Main.hx", :line_number => 248, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_value("hello"), %{:file_name => "Main.hx", :line_number => 251, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_value(42), %{:file_name => "Main.hx", :line_number => 252, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_value(3.14), %{:file_name => "Main.hx", :line_number => 253, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_value(true), %{:file_name => "Main.hx", :line_number => 254, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_value([1, 2, 3]), %{:file_name => "Main.hx", :line_number => 255, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(classify_value(nil), %{:file_name => "Main.hx", :line_number => 256, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(check_color("red"), %{:file_name => "Main.hx", :line_number => 259, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(check_color("orange"), %{:file_name => "Main.hx", :line_number => 260, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(check_color("black"), %{:file_name => "Main.hx", :line_number => 261, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(check_color("pink"), %{:file_name => "Main.hx", :line_number => 262, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_status("active"), %{:file_name => "Main.hx", :line_number => 265, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_status("paused"), %{:file_name => "Main.hx", :line_number => 266, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_status("error"), %{:file_name => "Main.hx", :line_number => 267, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(match_status("unknown"), %{:file_name => "Main.hx", :line_number => 268, :class_name => "Main", :method_name => "main"})
  end
end
