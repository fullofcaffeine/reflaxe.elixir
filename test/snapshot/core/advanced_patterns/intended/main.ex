defmodule Main do
  def match_simple_value(value) do
    case (value) do
      0 ->
        "zero"
      1 ->
        "one"
      2 ->
        "two"
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
  def process_array(arr) do
    case (length(arr)) do
      0 ->
        "empty"
      1 ->
        g = arr[0]
        x = g
        "single: " <> Kernel.to_string(x)
      2 ->
        g = arr[0]
        g1 = arr[1]
        x = g
        y = g1
        "pair: " <> Kernel.to_string(x) <> "," <> Kernel.to_string(y)
      3 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        x = g
        y = g1
        z = g2
        "triple: " <> Kernel.to_string(x) <> "," <> Kernel.to_string(y) <> "," <> Kernel.to_string(z)
      4 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        g3 = arr[3]
        first = g
        second = g1
        third = g2
        fourth = g3
        "quad: " <> Kernel.to_string(first) <> "," <> Kernel.to_string(second) <> "," <> Kernel.to_string(third) <> "," <> Kernel.to_string(fourth)
      _ ->
        a = arr
        if (length(a) > 4) do
          "many: " <> Kernel.to_string(length(a)) <> " elements"
        else
          "unknown"
        end
    end
  end
  def classify_string(str) do
    case (str) do
      "" ->
        "empty"
      "goodbye" ->
        "farewell"
      "hello" ->
        "greeting"
      _ ->
        s = str
        if (length(s) == 1) do
          "single char"
        else
          s = str
          if (length(s) > 10 && length(s) <= 20) do
            "medium"
          else
            s = str
            if (length(s) > 20), do: "long", else: "other"
          end
        end
    end
  end
  def classify_number(n) do
    if (n == 0) do
      "zero"
    else
      x = n
      if (x > 0 && x <= 1) do
        "tiny"
      else
        x = n
        if (x > 1 && x <= 10) do
          "small"
        else
          x = n
          if (x > 10 && x <= 100) do
            "medium"
          else
            x = n
            if (x > 100 && x <= 1000) do
              "large"
            else
              x = n
              if (x > 1000) do
                "huge"
              else
                x = n
                if (x < 0 && x >= -10) do
                  "small negative"
                else
                  x = n
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
    if active do
      if verified do
        if premium, do: "full access", else: "verified user"
      else
        if premium, do: "unverified premium", else: "basic user"
      end
    else
      "inactive"
    end
  end
  def match_matrix(matrix) do
    case (length(matrix)) do
      0 ->
        "empty matrix"
      1 ->
        g = matrix[0]
        if (length(g) == 1) do
          g = g[0]
          x = g
          "single element: " <> Kernel.to_string(x)
        else
          m = matrix
          if (length(m) == length(m[0])) do
            "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
          else
            "non-square matrix"
          end
        end
      2 ->
        g = matrix[0]
        g1 = matrix[1]
        if (length(g) == 2) do
          g2 = g[0]
          g = g[1]
          if (length(g1) == 2) do
            g3 = g1[0]
            g1 = g1[1]
            c = g3
            d = g1
            b = g
            a = g2
            "2x2 matrix: [[" <> Kernel.to_string(a) <> "," <> Kernel.to_string(b) <> "],[" <> Kernel.to_string(c) <> "," <> Kernel.to_string(d) <> "]]"
          else
            m = matrix
            if (length(m) == length(m[0])) do
              "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
            else
              "non-square matrix"
            end
          end
        else
          m = matrix
          if (length(m) == length(m[0])) do
            "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
          else
            "non-square matrix"
          end
        end
      3 ->
        g = matrix[0]
        g1 = matrix[1]
        g2 = matrix[2]
        if (length(g) == 3) do
          g3 = g[0]
          g4 = g[1]
          g = g[2]
          if (length(g1) == 3) do
            g5 = g1[0]
            g6 = g1[1]
            g1 = g1[2]
            if (length(g2) == 3) do
              g7 = g2[0]
              g8 = g2[1]
              g2 = g2[2]
              _g = g7
              _h = g8
              _i = g2
              _a = g3
              _b = g4
              _c = g
              _f = g1
              _e = g6
              _d = g5
              "3x3 matrix"
            else
              m = matrix
              if (length(m) == length(m[0])) do
                "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
              else
                "non-square matrix"
              end
            end
          else
            m = matrix
            if (length(m) == length(m[0])) do
              "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
            else
              "non-square matrix"
            end
          end
        else
          m = matrix
          if (length(m) == length(m[0])) do
            "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
          else
            "non-square matrix"
          end
        end
      _ ->
        m = matrix
        if (length(m) == length(m[0])) do
          "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
        else
          "non-square matrix"
        end
    end
  end
  def validate_age(_age, has_permission) do
    a = _age
    if (a < 0) do
      "invalid age"
    else
      a = _age
      if (a >= 0 && a < 13) do
        "child"
      else
        case (has_permission) do
          false ->
            a = _age
            if (a >= 13 && a < 18) do
              "teen without permission"
            else
              a = _age
              if (a >= 18 && a < 21) do
                "young adult"
              else
                a = _age
                if (a >= 21 && a < 65) do
                  "adult"
                else
                  a = _age
                  if (a >= 65), do: "senior", else: "unknown"
                end
              end
            end
          true ->
            a = _age
            if (a >= 13 && a < 18) do
              "teen with permission"
            else
              a = _age
              if (a >= 18 && a < 21) do
                "young adult"
              else
                a = _age
                if (a >= 21 && a < 65) do
                  "adult"
                else
                  a = _age
                  if (a >= 65), do: "senior", else: "unknown"
                end
              end
            end
          _ ->
            a = _age
            if (a >= 18 && a < 21) do
              "young adult"
            else
              a = _age
              if (a >= 21 && a < 65) do
                "adult"
              else
                a = _age
                if (a >= 65), do: "senior", else: "unknown"
              end
            end
        end
      end
    end
  end
  def classify_value(value) do
    v = value
    if (Std.is(v, String)) do
      "string: \"" <> Std.string(v) <> "\""
    else
      v = value
      if (Std.is(v, Int)) do
        "integer: " <> Std.string(v)
      else
        v = value
        if (Std.is(v, Float)) do
          "float: " <> Std.string(v)
        else
          v = value
          if (Std.is(v, Bool)) do
            "boolean: " <> Std.string(v)
          else
            v = value
            if (Std.is(v, Array)) do
              "array of length " <> Std.string(length(v))
            else
              if (value == nil), do: "null value", else: "unknown type"
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
    if ((

                case Enum.find_index(primary_colors, fn item -> item == c end) do
                    nil -> -1
                    idx -> idx
                end
            
) >= 0) do
      "primary color"
    else
      c = color
      if ((

                case Enum.find_index(secondary_colors, fn item -> item == c end) do
                    nil -> -1
                    idx -> idx
                end
            
) >= 0) do
        "secondary color"
      else
        case (color) do
          "black" ->
            "monochrome"
          "gray" ->
            "monochrome"
          "white" ->
            "monochrome"
          _ ->
            "unknown color"
        end
      end
    end
  end
  def match_status(status) do
    case (status) do
      "crashed" ->
        "error state"
      "error" ->
        "error state"
      "failed" ->
        "error state"
      "disabled" ->
        "not operational"
      "offline" ->
        "not operational"
      "stopped" ->
        "not operational"
      "active" ->
        "operational"
      "online" ->
        "operational"
      "running" ->
        "operational"
      "paused" ->
        "temporarily stopped"
      "suspended" ->
        "temporarily stopped"
      "waiting" ->
        "temporarily stopped"
      _ ->
        "unknown status"
    end
  end
  def main() do
    Log.trace("Advanced pattern matching test", %{:file_name => "Main.hx", :line_number => 201, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(0), %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(42), %{:file_name => "Main.hx", :line_number => 205, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(-5), %{:file_name => "Main.hx", :line_number => 206, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(150), %{:file_name => "Main.hx", :line_number => 207, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([]), %{:file_name => "Main.hx", :line_number => 210, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([1]), %{:file_name => "Main.hx", :line_number => 211, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([1, 2]), %{:file_name => "Main.hx", :line_number => 212, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([1, 2, 3]), %{:file_name => "Main.hx", :line_number => 213, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([1, 2, 3, 4, 5]), %{:file_name => "Main.hx", :line_number => 214, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_string(""), %{:file_name => "Main.hx", :line_number => 217, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_string("hello"), %{:file_name => "Main.hx", :line_number => 218, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_string("x"), %{:file_name => "Main.hx", :line_number => 219, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_string("medium length string"), %{:file_name => "Main.hx", :line_number => 220, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_string("this is a very long string that exceeds twenty characters"), %{:file_name => "Main.hx", :line_number => 221, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(0), %{:file_name => "Main.hx", :line_number => 224, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(0.5), %{:file_name => "Main.hx", :line_number => 225, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(5), %{:file_name => "Main.hx", :line_number => 226, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(50), %{:file_name => "Main.hx", :line_number => 227, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(500), %{:file_name => "Main.hx", :line_number => 228, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(5000), %{:file_name => "Main.hx", :line_number => 229, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(-5), %{:file_name => "Main.hx", :line_number => 230, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_number(-50), %{:file_name => "Main.hx", :line_number => 231, :class_name => "Main", :method_name => "main"})
    Log.trace(match_flags(true, true, true), %{:file_name => "Main.hx", :line_number => 234, :class_name => "Main", :method_name => "main"})
    Log.trace(match_flags(true, true, false), %{:file_name => "Main.hx", :line_number => 235, :class_name => "Main", :method_name => "main"})
    Log.trace(match_flags(false, false, false), %{:file_name => "Main.hx", :line_number => 236, :class_name => "Main", :method_name => "main"})
    Log.trace(match_matrix([]), %{:file_name => "Main.hx", :line_number => 239, :class_name => "Main", :method_name => "main"})
    Log.trace(match_matrix([[1]]), %{:file_name => "Main.hx", :line_number => 240, :class_name => "Main", :method_name => "main"})
    Log.trace(match_matrix([[1, 2], [3, 4]]), %{:file_name => "Main.hx", :line_number => 241, :class_name => "Main", :method_name => "main"})
    Log.trace(match_matrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]]), %{:file_name => "Main.hx", :line_number => 242, :class_name => "Main", :method_name => "main"})
    Log.trace(validate_age(10, false), %{:file_name => "Main.hx", :line_number => 245, :class_name => "Main", :method_name => "main"})
    Log.trace(validate_age(15, true), %{:file_name => "Main.hx", :line_number => 246, :class_name => "Main", :method_name => "main"})
    Log.trace(validate_age(25, false), %{:file_name => "Main.hx", :line_number => 247, :class_name => "Main", :method_name => "main"})
    Log.trace(validate_age(70, true), %{:file_name => "Main.hx", :line_number => 248, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_value("hello"), %{:file_name => "Main.hx", :line_number => 251, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_value(42), %{:file_name => "Main.hx", :line_number => 252, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_value(3.14), %{:file_name => "Main.hx", :line_number => 253, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_value(true), %{:file_name => "Main.hx", :line_number => 254, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_value([1, 2, 3]), %{:file_name => "Main.hx", :line_number => 255, :class_name => "Main", :method_name => "main"})
    Log.trace(classify_value(nil), %{:file_name => "Main.hx", :line_number => 256, :class_name => "Main", :method_name => "main"})
    Log.trace(check_color("red"), %{:file_name => "Main.hx", :line_number => 259, :class_name => "Main", :method_name => "main"})
    Log.trace(check_color("orange"), %{:file_name => "Main.hx", :line_number => 260, :class_name => "Main", :method_name => "main"})
    Log.trace(check_color("black"), %{:file_name => "Main.hx", :line_number => 261, :class_name => "Main", :method_name => "main"})
    Log.trace(check_color("pink"), %{:file_name => "Main.hx", :line_number => 262, :class_name => "Main", :method_name => "main"})
    Log.trace(match_status("active"), %{:file_name => "Main.hx", :line_number => 265, :class_name => "Main", :method_name => "main"})
    Log.trace(match_status("paused"), %{:file_name => "Main.hx", :line_number => 266, :class_name => "Main", :method_name => "main"})
    Log.trace(match_status("error"), %{:file_name => "Main.hx", :line_number => 267, :class_name => "Main", :method_name => "main"})
    Log.trace(match_status("unknown"), %{:file_name => "Main.hx", :line_number => 268, :class_name => "Main", :method_name => "main"})
  end
end