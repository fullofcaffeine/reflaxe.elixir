defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc """
    Simple enum-like pattern matching

  """
  @spec match_simple_value(integer()) :: String.t()
  def match_simple_value(value) do
    temp_result = nil
    case (value) do
      0 ->
        temp_result = "zero"
      1 ->
        temp_result = "one"
      2 ->
        temp_result = "two"
      _ ->
        n = value
        if (n < 0) do
          temp_result = "negative"
        else
          n = value
          temp_result = if (n > 100), do: "large", else: "other"
        end
    end
    temp_result
  end

  @doc """
    Array pattern matching with guards

  """
  @spec process_array(Array.t()) :: String.t()
  def process_array(arr) do
    temp_result = nil
    case (arr.length) do
      0 ->
        temp_result = "empty"
      1 ->
        g = Enum.at(arr, 0)
        x = g
        temp_result = "single: " <> Integer.to_string(x)
      2 ->
        _g_1 = Enum.at(arr, 0)
        _g_1 = Enum.at(arr, 1)
        x = _g_1
        y = _g_1
        temp_result = "pair: " ++ x ++ "," ++ y
      3 ->
        _g_1 = Enum.at(arr, 0)
        _g_1 = Enum.at(arr, 1)
        _g_2 = Enum.at(arr, 2)
        x = _g_2
        y = _g_2
        z = _g_2
        temp_result = "triple: " ++ x ++ "," ++ y ++ "," ++ z
      4 ->
        _g_1 = Enum.at(arr, 0)
        _g_1 = Enum.at(arr, 1)
        _g_2 = Enum.at(arr, 2)
        _g_3 = Enum.at(arr, 3)
        first = _g_3
        second = _g_3
        third = _g_3
        fourth = _g_3
        temp_result = "quad: " ++ first ++ "," ++ second ++ "," ++ third ++ "," ++ fourth
      _ ->
        a = arr
        temp_result = if (a.length > 4), do: "many: " <> Integer.to_string(a.length) <> " elements", else: "unknown"
    end
    temp_result
  end

  @doc """
    String pattern matching with guards

  """
  @spec classify_string(String.t()) :: String.t()
  def classify_string(str) do
    temp_result = nil
    case (str) do
      "" ->
        temp_result = "empty"
      "goodbye" ->
        temp_result = "farewell"
      "hello" ->
        temp_result = "greeting"
      _ ->
        s = str
        if (s.length == 1) do
          temp_result = "single char"
        else
          s = str
          if (s.length > 10 && s.length <= 20) do
            temp_result = "medium"
          else
            s = str
            temp_result = if (s.length > 20), do: "long", else: "other"
          end
        end
    end
    temp_result
  end

  @doc """
    Complex number range guards

  """
  @spec classify_number(float()) :: String.t()
  def classify_number(n) do
    temp_result = nil
    if (n == 0.0) do
      temp_result = "zero"
    else
      x = n
      if (x > 0 && x <= 1) do
        temp_result = "tiny"
      else
        x = n
        if (x > 1 && x <= 10) do
          temp_result = "small"
        else
          x = n
          if (x > 10 && x <= 100) do
            temp_result = "medium"
          else
            x = n
            if (x > 100 && x <= 1000) do
              temp_result = "large"
            else
              x = n
              if (x > 1000) do
                temp_result = "huge"
              else
                x = n
                if (x < 0 && x >= -10) do
                  temp_result = "small negative"
                else
                  x = n
                  temp_result = if (x < -10), do: "large negative", else: "unknown"
                end
              end
            end
          end
        end
      end
    end
    temp_result
  end

  @doc """
    Boolean combinations with tuples

  """
  @spec match_flags(boolean(), boolean(), boolean()) :: String.t()
  def match_flags(active, verified, premium) do
    temp_result = nil
    if (active), do: if (verified), do: temp_result = if (premium), do: "full access", else: "verified user", else: temp_result = if (premium), do: "unverified premium", else: "basic user", else: temp_result = "inactive"
    temp_result
  end

  @doc """
    Nested array patterns

  """
  @spec match_matrix(Array.t()) :: String.t()
  def match_matrix(matrix) do
    temp_result = nil
    case (matrix.length) do
      0 ->
        temp_result = "empty matrix"
      1 ->
        g = Enum.at(matrix, 0)
        if (g.length == 1) do
          g = Enum.at(g, 0)
          x = g
          temp_result = "single element: " <> Integer.to_string(x)
        else
          m = matrix
          temp_result = if (m.length == Enum.at(m, 0).length), do: "square matrix " <> Integer.to_string(m.length) <> "x" <> Integer.to_string(m.length), else: "non-square matrix"
        end
      2 ->
        _g_1 = Enum.at(matrix, 0)
        _g_1 = Enum.at(matrix, 1)
        if (g.length == 2), do: _g_1 = Enum.at(g, 0)
        _g_1 = Enum.at(g, 1)
        if (g.length == 2), do: _g_1 = Enum.at(g, 0)
        _g_1 = Enum.at(g, 1)
        c = _g_1
        d = _g_1
        b = _g_1
        a = _g_1
        temp_result = "2x2 matrix: [[" ++ a ++ "," ++ b ++ "],[" ++ c ++ "," ++ d ++ "]]", else: m = matrix
        if (m.length == Enum.at(m, 0).length), do: temp_result = "square matrix " ++ Enum.count(m) ++ "x" ++ Enum.count(m), else: temp_result = "non-square matrix", else: m = matrix
        if (m.length == Enum.at(m, 0).length), do: temp_result = "square matrix " ++ Enum.count(m) ++ "x" ++ Enum.count(m), else: temp_result = "non-square matrix"
      3 ->
        _g_1 = Enum.at(matrix, 0)
        _g_1 = Enum.at(matrix, 1)
        _g_2 = Enum.at(matrix, 2)
        if (g.length == 3), do: _g_2 = Enum.at(g, 0)
        _g_2 = Enum.at(g, 1)
        _g_2 = Enum.at(g, 2)
        if (g.length == 3), do: _g_2 = Enum.at(g, 0)
        _g_2 = Enum.at(g, 1)
        _g_2 = Enum.at(g, 2)
        if (g.length == 3), do: _g_2 = Enum.at(g, 0)
        _g_2 = Enum.at(g, 1)
        _g_2 = Enum.at(g, 2)
        g = _g_2
        h = _g_2
        i = _g_2
        a = _g_2
        b = _g_2
        c = _g_2
        f = _g_2
        e = _g_2
        d = _g_2
        temp_result = "3x3 matrix", else: m = matrix
        if (m.length == Enum.at(m, 0).length), do: temp_result = "square matrix " ++ Enum.count(m) ++ "x" ++ Enum.count(m), else: temp_result = "non-square matrix", else: m = matrix
        if (m.length == Enum.at(m, 0).length), do: temp_result = "square matrix " ++ Enum.count(m) ++ "x" ++ Enum.count(m), else: temp_result = "non-square matrix", else: m = matrix
        if (m.length == Enum.at(m, 0).length), do: temp_result = "square matrix " ++ Enum.count(m) ++ "x" ++ Enum.count(m), else: temp_result = "non-square matrix"
      _ ->
        m = matrix
        temp_result = if (m.length == Enum.at(m, 0).length), do: "square matrix " <> Integer.to_string(m.length) <> "x" <> Integer.to_string(m.length), else: "non-square matrix"
    end
    temp_result
  end

  @doc """
    Multiple guard conditions

  """
  @spec validate_age(integer(), boolean()) :: String.t()
  def validate_age(age, has_permission) do
    temp_result = nil
    a = age
    if (a < 0) do
      temp_result = "invalid age"
    else
      a = age
      if (a >= 0 && a < 13) do
        temp_result = "child"
      else
        case (has_permission) do
          false ->
            a = age
            if (a >= 13 && a < 18) do
              temp_result = "teen without permission"
            else
              a = age
              if (a >= 18 && a < 21) do
                temp_result = "young adult"
              else
                a = age
                if (a >= 21 && a < 65) do
                  temp_result = "adult"
                else
                  a = age
                  temp_result = if (a >= 65), do: "senior", else: "unknown"
                end
              end
            end
          true ->
            a = age
            if (a >= 13 && a < 18) do
              temp_result = "teen with permission"
            else
              a = age
              if (a >= 18 && a < 21) do
                temp_result = "young adult"
              else
                a = age
                if (a >= 21 && a < 65) do
                  temp_result = "adult"
                else
                  a = age
                  temp_result = if (a >= 65), do: "senior", else: "unknown"
                end
              end
            end
          _ ->
            a = age
            if (a >= 18 && a < 21) do
              temp_result = "young adult"
            else
              a = age
              if (a >= 21 && a < 65) do
                temp_result = "adult"
              else
                a = age
                temp_result = if (a >= 65), do: "senior", else: "unknown"
              end
            end
        end
      end
    end
    temp_result
  end

  @doc """
    Type checking guards (simulating is_binary, is_integer, etc.)

  """
  @spec classify_value(term()) :: String.t()
  def classify_value(value) do
    temp_result = nil
    v = value
    if (Std.is_of_type(v, String)) do
      temp_result = "string: \"" <> Std.string(v) <> "\""
    else
      v = value
      if (Std.is_of_type(v, Int)) do
        temp_result = "integer: " <> Std.string(v)
      else
        v = value
        if (Std.is_of_type(v, Float)) do
          temp_result = "float: " <> Std.string(v)
        else
          v = value
          if (Std.is_of_type(v, Bool)) do
            temp_result = "boolean: " <> Std.string(v)
          else
            v = value
            if (Std.is_of_type(v, Array)), do: temp_result = "array of length " <> Std.string(v.length), else: temp_result = if (value == nil), do: "null value", else: "unknown type"
          end
        end
      end
    end
    temp_result
  end

  @doc """
    List membership simulation

  """
  @spec check_color(String.t()) :: String.t()
  def check_color(color) do
    primary_colors = ["red", "green", "blue"]
    secondary_colors = ["orange", "purple", "yellow"]
    temp_result = nil
    c = color
    if (primary_colors.index_of(c) >= 0) do
      temp_result = "primary color"
    else
      c = color
      if (secondary_colors.index_of(c) >= 0) do
        temp_result = "secondary color"
      else
        case (color) do
          "black" ->
            temp_result = "monochrome"
          "gray" ->
            temp_result = "monochrome"
          "white" ->
            temp_result = "monochrome"
          _ ->
            temp_result = "unknown color"
        end
      end
    end
    temp_result
  end

  @doc """
    Combined patterns with OR

  """
  @spec match_status(String.t()) :: String.t()
  def match_status(status) do
    temp_result = nil
    case (status) do
      "crashed" ->
        temp_result = "error state"
      "error" ->
        temp_result = "error state"
      "failed" ->
        temp_result = "error state"
      "disabled" ->
        temp_result = "not operational"
      "offline" ->
        temp_result = "not operational"
      "stopped" ->
        temp_result = "not operational"
      "active" ->
        temp_result = "operational"
      "online" ->
        temp_result = "operational"
      "running" ->
        temp_result = "operational"
      "paused" ->
        temp_result = "temporarily stopped"
      "suspended" ->
        temp_result = "temporarily stopped"
      "waiting" ->
        temp_result = "temporarily stopped"
      _ ->
        temp_result = "unknown status"
    end
    temp_result
  end

  @doc "Function main"
  @spec main() :: nil
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
