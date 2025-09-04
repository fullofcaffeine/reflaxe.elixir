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
    case (arr.length) do
      0 ->
        "empty"
      1 ->
        g = arr[0]
        x = g
        "single: " <> x
      2 ->
        g = arr[0]
        g1 = arr[1]
        x = g
        y = g1
        "pair: " <> x <> "," <> y
      3 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        x = g
        y = g1
        z = g2
        "triple: " <> x <> "," <> y <> "," <> z
      4 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        g3 = arr[3]
        first = g
        second = g1
        third = g2
        fourth = g3
        "quad: " <> first <> "," <> second <> "," <> third <> "," <> fourth
      _ ->
        a = arr
        if (a.length > 4), do: "many: " <> a.length <> " elements", else: "unknown"
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
        if (s.length == 1) do
          "single char"
        else
          s = str
          if (s.length > 10 && s.length <= 20) do
            "medium"
          else
            s = str
            if (s.length > 20), do: "long", else: "other"
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
    case (matrix.length) do
      0 ->
        "empty matrix"
      1 ->
        g = matrix[0]
        if (g.length == 1) do
          g = g[0]
          x = g
          "single element: " <> x
        else
          m = matrix
          if (m.length == m[0].length), do: "square matrix " <> m.length <> "x" <> m.length, else: "non-square matrix"
        end
      2 ->
        g = matrix[0]
        g1 = matrix[1]
        if (g.length == 2) do
          g2 = g[0]
          g = g[1]
          if (g1.length == 2) do
            g3 = g1[0]
            g1 = g1[1]
            c = g3
            d = g1
            b = g
            a = g2
            "2x2 matrix: [[" <> a <> "," <> b <> "],[" <> c <> "," <> d <> "]]"
          else
            m = matrix
            if (m.length == m[0].length), do: "square matrix " <> m.length <> "x" <> m.length, else: "non-square matrix"
          end
        else
          m = matrix
          if (m.length == m[0].length), do: "square matrix " <> m.length <> "x" <> m.length, else: "non-square matrix"
        end
      3 ->
        g = matrix[0]
        g1 = matrix[1]
        g2 = matrix[2]
        if (g.length == 3) do
          g3 = g[0]
          g4 = g[1]
          g = g[2]
          if (g1.length == 3) do
            g5 = g1[0]
            g6 = g1[1]
            g1 = g1[2]
            if (g2.length == 3) do
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
              if (m.length == m[0].length), do: "square matrix " <> m.length <> "x" <> m.length, else: "non-square matrix"
            end
          else
            m = matrix
            if (m.length == m[0].length), do: "square matrix " <> m.length <> "x" <> m.length, else: "non-square matrix"
          end
        else
          m = matrix
          if (m.length == m[0].length), do: "square matrix " <> m.length <> "x" <> m.length, else: "non-square matrix"
        end
      _ ->
        m = matrix
        if (m.length == m[0].length), do: "square matrix " <> m.length <> "x" <> m.length, else: "non-square matrix"
    end
  end
  def validate_age(age, has_permission) do
    a = age
    if (a < 0) do
      "invalid age"
    else
      a = age
      if (a >= 0 && a < 13) do
        "child"
      else
        case (has_permission) do
          false ->
            a = age
            if (a >= 13 && a < 18) do
              "teen without permission"
            else
              a = age
              if (a >= 18 && a < 21) do
                "young adult"
              else
                a = age
                if (a >= 21 && a < 65) do
                  "adult"
                else
                  a = age
                  if (a >= 65), do: "senior", else: "unknown"
                end
              end
            end
          true ->
            a = age
            if (a >= 13 && a < 18) do
              "teen with permission"
            else
              a = age
              if (a >= 18 && a < 21) do
                "young adult"
              else
                a = age
                if (a >= 21 && a < 65) do
                  "adult"
                else
                  a = age
                  if (a >= 65), do: "senior", else: "unknown"
                end
              end
            end
          _ ->
            a = age
            if (a >= 18 && a < 21) do
              "young adult"
            else
              a = age
              if (a >= 21 && a < 65) do
                "adult"
              else
                a = age
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
              "array of length " <> Std.string(v.length)
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
    if (Enum.find_index(primary_colors, fn item -> item == c end) || -1 >= 0) do
      "primary color"
    else
      c = color
      if (Enum.find_index(secondary_colors, fn item -> item == c end) || -1 >= 0) do
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
    Log.trace("Advanced pattern matching test", %{:fileName => "Main.hx", :lineNumber => 201, :className => "Main", :methodName => "main"})
    Log.trace(match_simple_value(0), %{:fileName => "Main.hx", :lineNumber => 204, :className => "Main", :methodName => "main"})
    Log.trace(match_simple_value(42), %{:fileName => "Main.hx", :lineNumber => 205, :className => "Main", :methodName => "main"})
    Log.trace(match_simple_value(-5), %{:fileName => "Main.hx", :lineNumber => 206, :className => "Main", :methodName => "main"})
    Log.trace(match_simple_value(150), %{:fileName => "Main.hx", :lineNumber => 207, :className => "Main", :methodName => "main"})
    Log.trace(process_array([]), %{:fileName => "Main.hx", :lineNumber => 210, :className => "Main", :methodName => "main"})
    Log.trace(process_array([1]), %{:fileName => "Main.hx", :lineNumber => 211, :className => "Main", :methodName => "main"})
    Log.trace(process_array([1, 2]), %{:fileName => "Main.hx", :lineNumber => 212, :className => "Main", :methodName => "main"})
    Log.trace(process_array([1, 2, 3]), %{:fileName => "Main.hx", :lineNumber => 213, :className => "Main", :methodName => "main"})
    Log.trace(process_array([1, 2, 3, 4, 5]), %{:fileName => "Main.hx", :lineNumber => 214, :className => "Main", :methodName => "main"})
    Log.trace(classify_string(""), %{:fileName => "Main.hx", :lineNumber => 217, :className => "Main", :methodName => "main"})
    Log.trace(classify_string("hello"), %{:fileName => "Main.hx", :lineNumber => 218, :className => "Main", :methodName => "main"})
    Log.trace(classify_string("x"), %{:fileName => "Main.hx", :lineNumber => 219, :className => "Main", :methodName => "main"})
    Log.trace(classify_string("medium length string"), %{:fileName => "Main.hx", :lineNumber => 220, :className => "Main", :methodName => "main"})
    Log.trace(classify_string("this is a very long string that exceeds twenty characters"), %{:fileName => "Main.hx", :lineNumber => 221, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(0), %{:fileName => "Main.hx", :lineNumber => 224, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(0.5), %{:fileName => "Main.hx", :lineNumber => 225, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(5), %{:fileName => "Main.hx", :lineNumber => 226, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(50), %{:fileName => "Main.hx", :lineNumber => 227, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(500), %{:fileName => "Main.hx", :lineNumber => 228, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(5000), %{:fileName => "Main.hx", :lineNumber => 229, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(-5), %{:fileName => "Main.hx", :lineNumber => 230, :className => "Main", :methodName => "main"})
    Log.trace(classify_number(-50), %{:fileName => "Main.hx", :lineNumber => 231, :className => "Main", :methodName => "main"})
    Log.trace(match_flags(true, true, true), %{:fileName => "Main.hx", :lineNumber => 234, :className => "Main", :methodName => "main"})
    Log.trace(match_flags(true, true, false), %{:fileName => "Main.hx", :lineNumber => 235, :className => "Main", :methodName => "main"})
    Log.trace(match_flags(false, false, false), %{:fileName => "Main.hx", :lineNumber => 236, :className => "Main", :methodName => "main"})
    Log.trace(match_matrix([]), %{:fileName => "Main.hx", :lineNumber => 239, :className => "Main", :methodName => "main"})
    Log.trace(match_matrix([[1]]), %{:fileName => "Main.hx", :lineNumber => 240, :className => "Main", :methodName => "main"})
    Log.trace(match_matrix([[1, 2], [3, 4]]), %{:fileName => "Main.hx", :lineNumber => 241, :className => "Main", :methodName => "main"})
    Log.trace(match_matrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]]), %{:fileName => "Main.hx", :lineNumber => 242, :className => "Main", :methodName => "main"})
    Log.trace(validate_age(10, false), %{:fileName => "Main.hx", :lineNumber => 245, :className => "Main", :methodName => "main"})
    Log.trace(validate_age(15, true), %{:fileName => "Main.hx", :lineNumber => 246, :className => "Main", :methodName => "main"})
    Log.trace(validate_age(25, false), %{:fileName => "Main.hx", :lineNumber => 247, :className => "Main", :methodName => "main"})
    Log.trace(validate_age(70, true), %{:fileName => "Main.hx", :lineNumber => 248, :className => "Main", :methodName => "main"})
    Log.trace(classify_value("hello"), %{:fileName => "Main.hx", :lineNumber => 251, :className => "Main", :methodName => "main"})
    Log.trace(classify_value(42), %{:fileName => "Main.hx", :lineNumber => 252, :className => "Main", :methodName => "main"})
    Log.trace(classify_value(3.14), %{:fileName => "Main.hx", :lineNumber => 253, :className => "Main", :methodName => "main"})
    Log.trace(classify_value(true), %{:fileName => "Main.hx", :lineNumber => 254, :className => "Main", :methodName => "main"})
    Log.trace(classify_value([1, 2, 3]), %{:fileName => "Main.hx", :lineNumber => 255, :className => "Main", :methodName => "main"})
    Log.trace(classify_value(nil), %{:fileName => "Main.hx", :lineNumber => 256, :className => "Main", :methodName => "main"})
    Log.trace(check_color("red"), %{:fileName => "Main.hx", :lineNumber => 259, :className => "Main", :methodName => "main"})
    Log.trace(check_color("orange"), %{:fileName => "Main.hx", :lineNumber => 260, :className => "Main", :methodName => "main"})
    Log.trace(check_color("black"), %{:fileName => "Main.hx", :lineNumber => 261, :className => "Main", :methodName => "main"})
    Log.trace(check_color("pink"), %{:fileName => "Main.hx", :lineNumber => 262, :className => "Main", :methodName => "main"})
    Log.trace(match_status("active"), %{:fileName => "Main.hx", :lineNumber => 265, :className => "Main", :methodName => "main"})
    Log.trace(match_status("paused"), %{:fileName => "Main.hx", :lineNumber => 266, :className => "Main", :methodName => "main"})
    Log.trace(match_status("error"), %{:fileName => "Main.hx", :lineNumber => 267, :className => "Main", :methodName => "main"})
    Log.trace(match_status("unknown"), %{:fileName => "Main.hx", :lineNumber => 268, :className => "Main", :methodName => "main"})
  end
end