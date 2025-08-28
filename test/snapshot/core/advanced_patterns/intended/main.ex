defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe matchSimpleValue"
  def match_simple_value(value) do
    temp_result = nil

    temp_result = nil

    case (value) do
      _ ->
        "zero"
      _ ->
        "one"
      _ ->
        "two"
      _ -> n = value
    if ((n < 0)) do
      temp_result = "negative"
    else
      n = value
      if ((n > 100)), do: temp_result = "large", else: temp_result = "other"
    end
    end

    temp_result
  end

  @doc "Generated from Haxe processArray"
  def process_array(arr) do
    temp_result = nil

    case (arr.length) do
      _ ->
        temp_result = "empty"
      _ ->
        g_array = Enum.at(arr, 0)
    x = g_array
    temp_result = "single: " <> to_string(x)
      _ ->
        g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    x = g_array
    y = g_array
    temp_result = "pair: " <> to_string(x) <> "," <> to_string(y)
      _ ->
        g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    g_array = Enum.at(arr, 2)
    x = g_array
    y = g_array
    z = g_array
    temp_result = "triple: " <> to_string(x) <> "," <> to_string(y) <> "," <> to_string(z)
      _ ->
        g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    g_array = Enum.at(arr, 2)
    g_array = Enum.at(arr, 3)
    first = g_array
    second = g_array
    third = g_array
    fourth = g_array
    temp_result = "quad: " <> to_string(first) <> "," <> to_string(second) <> "," <> to_string(third) <> "," <> to_string(fourth)
      _ -> a = arr
    if ((a.length > 4)), do: temp_result = "many: " <> to_string(a.length) <> " elements", else: temp_result = "unknown"
    end

    temp_result
  end

  @doc "Generated from Haxe classifyString"
  def classify_string(str) do
    temp_result = nil

    case (str) do
      _ -> s = str
    if ((s.length == 1)) do
      temp_result = "single char"
    else
      s = str
      if (((s.length > 10) && (s.length <= 20))) do
        temp_result = "medium"
      else
        s = str
        if ((s.length > 20)), do: temp_result = "long", else: temp_result = "other"
      end
    end
    end

    temp_result
  end

  @doc "Generated from Haxe classifyNumber"
  def classify_number(n) do
    temp_result = nil

    if ((n == 0.0)) do
      temp_result = "zero"
    else
      x = n
      if (((x > 0) && (x <= 1))) do
        temp_result = "tiny"
      else
        x = n
        if (((x > 1) && (x <= 10))) do
          temp_result = "small"
        else
          x = n
          if (((x > 10) && (x <= 100))) do
            temp_result = "medium"
          else
            x = n
            if (((x > 100) && (x <= 1000))) do
              temp_result = "large"
            else
              x = n
              if ((x > 1000)) do
                temp_result = "huge"
              else
                x = n
                if (((x < 0) && (x >= -10))) do
                  temp_result = "small negative"
                else
                  x = n
                  if ((x < -10)), do: temp_result = "large negative", else: temp_result = "unknown"
                end
              end
            end
          end
        end
      end
    end

    temp_result
  end

  @doc "Generated from Haxe matchFlags"
  def match_flags(active, verified, premium) do
    temp_result = nil

    if active do
      if verified do
        if premium, do: temp_result = "full access", else: temp_result = "verified user"
      else
        if premium, do: temp_result = "unverified premium", else: temp_result = "basic user"
      end
    else
      temp_result = "inactive"
    end

    temp_result
  end

  @doc "Generated from Haxe matchMatrix"
  def match_matrix(matrix) do
    temp_result = nil

    case (matrix.length) do
      _ ->
        temp_result = "empty matrix"
      _ ->
        g_array = Enum.at(matrix, 0)
    if ((g_array.length == 1)) do
      g_array = Enum.at(g_array, 0)
      x = g_array
      temp_result = "single element: " <> to_string(x)
    else
      m = matrix
      if ((m.length == Enum.at(m, 0).length)), do: temp_result = "square matrix " <> to_string(m.length) <> "x" <> to_string(m.length), else: temp_result = "non-square matrix"
    end
      _ ->
        g_array = Enum.at(matrix, 0)
    g_array = Enum.at(matrix, 1)
    if ((g_array.length == 2)) do
      g_array = Enum.at(g_array, 0)
      g_array = Enum.at(g_array, 1)
      if ((g_array.length == 2)) do
        g_array = Enum.at(g_array, 0)
        g_array = Enum.at(g_array, 1)
        c = g_array
        d = g_array
        b = g_array
        a = g_array
        temp_result = "2x2 matrix: [[" <> to_string(a) <> "," <> to_string(b) <> "],[" <> to_string(c) <> "," <> to_string(d) <> "]]"
      else
        m = matrix
        if ((m.length == Enum.at(m, 0).length)), do: temp_result = "square matrix " <> to_string(m.length) <> "x" <> to_string(m.length), else: temp_result = "non-square matrix"
      end
    else
      m = matrix
      if ((m.length == Enum.at(m, 0).length)), do: temp_result = "square matrix " <> to_string(m.length) <> "x" <> to_string(m.length), else: temp_result = "non-square matrix"
    end
      _ ->
        g_array = Enum.at(matrix, 0)
    g_array = Enum.at(matrix, 1)
    g_array = Enum.at(matrix, 2)
    if ((g_array.length == 3)) do
      g_array = Enum.at(g_array, 0)
      g_array = Enum.at(g_array, 1)
      g_array = Enum.at(g_array, 2)
      if ((g_array.length == 3)) do
        g_array = Enum.at(g_array, 0)
        g_array = Enum.at(g_array, 1)
        g_array = Enum.at(g_array, 2)
        if ((g_array.length == 3)) do
          g_array = Enum.at(g_array, 0)
          g_array = Enum.at(g_array, 1)
          g_array = Enum.at(g_array, 2)
          g_array = g_array
          _h = g_array
          _i = g_array
          _a = g_array
          _b = g_array
          _c = g_array
          _f = g_array
          _e = g_array
          _d = g_array
          temp_result = "3x3 matrix"
        else
          m = matrix
          if ((m.length == Enum.at(m, 0).length)), do: temp_result = "square matrix " <> to_string(m.length) <> "x" <> to_string(m.length), else: temp_result = "non-square matrix"
        end
      else
        m = matrix
        if ((m.length == Enum.at(m, 0).length)), do: temp_result = "square matrix " <> to_string(m.length) <> "x" <> to_string(m.length), else: temp_result = "non-square matrix"
      end
    else
      m = matrix
      if ((m.length == Enum.at(m, 0).length)), do: temp_result = "square matrix " <> to_string(m.length) <> "x" <> to_string(m.length), else: temp_result = "non-square matrix"
    end
      _ -> m = matrix
    if ((m.length == Enum.at(m, 0).length)), do: temp_result = "square matrix " <> to_string(m.length) <> "x" <> to_string(m.length), else: temp_result = "non-square matrix"
    end

    temp_result
  end

  @doc "Generated from Haxe validateAge"
  def validate_age(age, has_permission) do
    temp_result = nil

    a = age
    if ((a < 0)) do
      temp_result = "invalid age"
    else
      a = age
      if (((a >= 0) && (a < 13))) do
        temp_result = "child"
      else
        case (has_permission) do
          _ -> a = age
        if (((a >= 18) && (a < 21))) do
          temp_result = "young adult"
        else
          a = age
          if (((a >= 21) && (a < 65))) do
            temp_result = "adult"
          else
            a = age
            if ((a >= 65)), do: temp_result = "senior", else: temp_result = "unknown"
          end
        end
        end
      end
    end

    temp_result
  end

  @doc "Generated from Haxe classifyValue"
  def classify_value(value) do
    temp_result = nil

    v = value
    if Std.is_of_type(v, String) do
      temp_result = "string: \"" <> Std.string(v) <> "\""
    else
      v = value
      if Std.is_of_type(v, Int) do
        temp_result = "integer: " <> Std.string(v)
      else
        v = value
        if Std.is_of_type(v, Float) do
          temp_result = "float: " <> Std.string(v)
        else
          v = value
          if Std.is_of_type(v, Bool) do
            temp_result = "boolean: " <> Std.string(v)
          else
            v = value
            if Std.is_of_type(v, Array) do
              temp_result = "array of length " <> Std.string(v.length)
            else
              if ((value == nil)), do: temp_result = "null value", else: temp_result = "unknown type"
            end
          end
        end
      end
    end

    temp_result
  end

  @doc "Generated from Haxe checkColor"
  def check_color(color) do
    temp_result = nil

    primary_colors = ["red", "green", "blue"]

    secondary_colors = ["orange", "purple", "yellow"]

    c = color
    if ((primary_colors.index_of(c) >= 0)) do
      temp_result = "primary color"
    else
      c = color
      if ((secondary_colors.index_of(c) >= 0)) do
        temp_result = "secondary color"
      else
        case (color) do
          _ -> "unknown color"
        end
      end
    end

    temp_result
  end

  @doc "Generated from Haxe matchStatus"
  def match_status(status) do
    temp_result = nil

    case (status) do
      _ -> "unknown status"
    end

    temp_result
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace("Advanced pattern matching test", %{"fileName" => "Main.hx", "lineNumber" => 201, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_simple_value(0), %{"fileName" => "Main.hx", "lineNumber" => 204, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_simple_value(42), %{"fileName" => "Main.hx", "lineNumber" => 205, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_simple_value(-5), %{"fileName" => "Main.hx", "lineNumber" => 206, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_simple_value(150), %{"fileName" => "Main.hx", "lineNumber" => 207, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_array([]), %{"fileName" => "Main.hx", "lineNumber" => 210, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_array([1]), %{"fileName" => "Main.hx", "lineNumber" => 211, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_array([1, 2]), %{"fileName" => "Main.hx", "lineNumber" => 212, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_array([1, 2, 3]), %{"fileName" => "Main.hx", "lineNumber" => 213, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_array([1, 2, 3, 4, 5]), %{"fileName" => "Main.hx", "lineNumber" => 214, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_string(""), %{"fileName" => "Main.hx", "lineNumber" => 217, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_string("hello"), %{"fileName" => "Main.hx", "lineNumber" => 218, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_string("x"), %{"fileName" => "Main.hx", "lineNumber" => 219, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_string("medium length string"), %{"fileName" => "Main.hx", "lineNumber" => 220, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_string("this is a very long string that exceeds twenty characters"), %{"fileName" => "Main.hx", "lineNumber" => 221, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(0.0), %{"fileName" => "Main.hx", "lineNumber" => 224, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(0.5), %{"fileName" => "Main.hx", "lineNumber" => 225, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(5.0), %{"fileName" => "Main.hx", "lineNumber" => 226, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(50.0), %{"fileName" => "Main.hx", "lineNumber" => 227, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(500.0), %{"fileName" => "Main.hx", "lineNumber" => 228, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(5000.0), %{"fileName" => "Main.hx", "lineNumber" => 229, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(-5.0), %{"fileName" => "Main.hx", "lineNumber" => 230, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_number(-50.0), %{"fileName" => "Main.hx", "lineNumber" => 231, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_flags(true, true, true), %{"fileName" => "Main.hx", "lineNumber" => 234, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_flags(true, true, false), %{"fileName" => "Main.hx", "lineNumber" => 235, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_flags(false, false, false), %{"fileName" => "Main.hx", "lineNumber" => 236, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_matrix([]), %{"fileName" => "Main.hx", "lineNumber" => 239, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_matrix([[1]]), %{"fileName" => "Main.hx", "lineNumber" => 240, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_matrix([[1, 2], [3, 4]]), %{"fileName" => "Main.hx", "lineNumber" => 241, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_matrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]]), %{"fileName" => "Main.hx", "lineNumber" => 242, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.validate_age(10, false), %{"fileName" => "Main.hx", "lineNumber" => 245, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.validate_age(15, true), %{"fileName" => "Main.hx", "lineNumber" => 246, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.validate_age(25, false), %{"fileName" => "Main.hx", "lineNumber" => 247, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.validate_age(70, true), %{"fileName" => "Main.hx", "lineNumber" => 248, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_value("hello"), %{"fileName" => "Main.hx", "lineNumber" => 251, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_value(42), %{"fileName" => "Main.hx", "lineNumber" => 252, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_value(3.14), %{"fileName" => "Main.hx", "lineNumber" => 253, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_value(true), %{"fileName" => "Main.hx", "lineNumber" => 254, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_value([1, 2, 3]), %{"fileName" => "Main.hx", "lineNumber" => 255, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.classify_value(nil), %{"fileName" => "Main.hx", "lineNumber" => 256, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.check_color("red"), %{"fileName" => "Main.hx", "lineNumber" => 259, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.check_color("orange"), %{"fileName" => "Main.hx", "lineNumber" => 260, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.check_color("black"), %{"fileName" => "Main.hx", "lineNumber" => 261, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.check_color("pink"), %{"fileName" => "Main.hx", "lineNumber" => 262, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_status("active"), %{"fileName" => "Main.hx", "lineNumber" => 265, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_status("paused"), %{"fileName" => "Main.hx", "lineNumber" => 266, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_status("error"), %{"fileName" => "Main.hx", "lineNumber" => 267, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.match_status("unknown"), %{"fileName" => "Main.hx", "lineNumber" => 268, "className" => "Main", "methodName" => "main"})
  end

end
