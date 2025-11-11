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
          n = value
          if (n > 100), do: "large", else: "other"
        end
    end)
  end
  def process_array(arr) do
    (case arr do
      [] -> "empty"
      [_head | _tail] -> "single: #{(fn -> Kernel.to_string(x) end).()}"
      2 -> "pair: #{(fn -> Kernel.to_string(x) end).()},#{(fn -> Kernel.to_string(y) end).()}"
      3 -> "triple: #{(fn -> Kernel.to_string(x) end).()},#{(fn -> Kernel.to_string(y) end).()},#{(fn -> Kernel.to_string(z) end).()}"
      4 -> "quad: #{(fn -> Kernel.to_string(first) end).()},#{(fn -> Kernel.to_string(second) end).()},#{(fn -> Kernel.to_string(third) end).()},#{(fn -> Kernel.to_string(fourth) end).()}"
      _ ->
        a = arr
        if (length(a) > 4) do
          "many: #{(fn -> Kernel.to_string(length(a)) end).()} elements"
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
          s = str
          if (length(s) > 10 and length(s) <= 20) do
            "medium"
          else
            s = str
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
        x = n
        if (x > 1 and x <= 10) do
          "small"
        else
          x = n
          if (x > 10 and x <= 100) do
            "medium"
          else
            x = n
            if (x > 100 and x <= 1000) do
              "large"
            else
              x = n
              if (x > 1000) do
                "huge"
              else
                x = n
                if (x < 0 and x >= -10) do
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
      [_head | _tail] when length(g) == 1 -> "single element: #{(fn -> Kernel.to_string(x) end).()}"
      [_head | _tail] when length(m) == length(_head) -> "square matrix #{(fn -> Kernel.to_string(length(m)) end).()}x#{(fn -> Kernel.to_string(length(m)) end).()}"
      [_head | _tail] -> "non-square matrix"
      2 ->
        cond do
          length(_g) == 2 ->
            g3 = _g[0]
            g1 = _g[1]
            "2x2 matrix: [[" <> Kernel.to_string(a) <> "," <> Kernel.to_string(b) <> "],[" <> Kernel.to_string(c) <> "," <> Kernel.to_string(d) <> "]]"
          length(m) == length(m[0]) -> "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
          true -> "non-square matrix"
        end
      2 when length(m) == length(m[0]) -> "square matrix #{(fn -> Kernel.to_string(length(m)) end).()}x#{(fn -> Kernel.to_string(length(m)) end).()}"
      2 -> "non-square matrix"
      3 ->
        cond do
          length(_g) == 3 ->
            g5 = _g[0]
            g6 = _g[1]
            g1 = _g[2]
            if (length(_g) == 3) do
              g7 = _g[0]
              g8 = _g[1]
              g2 = _g[2]
              h = _g8
              i = _g2
              a = _g3
              b = _g4
              c = _g
              f = _g1
              e = _g6
              d = _g5
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
      3 when length(m) == length(m[0]) -> "square matrix #{(fn -> Kernel.to_string(length(m)) end).()}x#{(fn -> Kernel.to_string(length(m)) end).()}"
      3 -> "non-square matrix"
      _ ->
        m = matrix
        if (length(m) == length(m[0])) do
          "square matrix #{(fn -> Kernel.to_string(length(m)) end).()}x#{(fn -> Kernel.to_string(length(m)) end).()}"
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
      a = age
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
            a = age
            if (a >= 18 and a < 21) do
              "young adult"
            else
              a = age
              if (a >= 21 and a < 65) do
                "adult"
              else
                a = age
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
      if (MyApp.Std.is(v, Int)) do
        "integer: #{(fn -> inspect(v) end).()}"
      else
        v = value
        if (MyApp.Std.is(v, Float)) do
          "float: #{(fn -> inspect(v) end).()}"
        else
          v = value
          if (MyApp.Std.is(v, Bool)) do
            "boolean: #{(fn -> inspect(v) end).()}"
          else
            v = value
            cond do
              Std.is(v, Array) -> "array of length " <> inspect(Map.get(v, :length))
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
      c = color
      if (
                case Enum.find_index(secondary_colors, fn item -> item == c end) do
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
    nil
  end
end
