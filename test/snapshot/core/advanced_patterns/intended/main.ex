defmodule Main do
  def match_simple_value(value) do
    (case value do
      0 -> "zero"
      1 -> "one"
      2 -> "two"
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
      s ->
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
      [head | _tail] ->
        cond do
          length(head) == 1 ->
            _g = head[0]
            x = head
            "single element: " <> Kernel.to_string(x)
          true ->
            m = matrix
            if (length(m) == length(m[0])) do
              "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
            else
              "non-square matrix"
            end
        end
      2 ->
        cond do
          length(g) == 2 ->
            g = g[1]
            if (length(g) == 2) do
              g = g[1]
              c = g
              d = g
              b = g
              a = g
              "2x2 matrix: [[" <> Kernel.to_string(a) <> "," <> Kernel.to_string(b) <> "],[" <> Kernel.to_string(c) <> "," <> Kernel.to_string(d) <> "]]"
            else
              m = matrix
              if (length(m) == length(m[0])) do
                "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
              else
                "non-square matrix"
              end
            end
          true ->
            m = matrix
            if (length(m) == length(m[0])) do
              "square matrix " <> Kernel.to_string(length(m)) <> "x" <> Kernel.to_string(length(m))
            else
              "non-square matrix"
            end
        end
      3 ->
        cond do
          length(g) == 3 ->
            g = g[2]
            if (length(g) == 3) do
              g = g[2]
              if (length(g) == 3) do
                g = g[2]
                _h = g
                _i = g
                _a = g
                _b = g
                _c = g
                _f = g
                _e = g
                _d = g
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
          true ->
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
    if (Std.is(v, String)) do
      "string: \"#{(fn -> inspect(v) end).()}\""
    else
      v = value
      if (Std.is(v, Int)) do
        "integer: #{(fn -> inspect(v) end).()}"
      else
        v = value
        if (Std.is(v, Float)) do
          "float: #{(fn -> inspect(v) end).()}"
        else
          v = value
          if (Std.is(v, Bool)) do
            "boolean: #{(fn -> inspect(v) end).()}"
          else
            v = value
            cond do
              Std.is(v, Array) -> "array of length " <> length(v)
              Kernel.is_nil(value) -> "null value"
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
          "gray" -> "monochrome"
          "white" -> "monochrome"
          _ -> "unknown color"
        end)
      end
    end
  end
  def match_status(status) do
    (case status do
      "crashed" -> "error state"
      "error" -> "error state"
      "failed" -> "error state"
      "disabled" -> "not operational"
      "offline" -> "not operational"
      "stopped" -> "not operational"
      "active" -> "operational"
      "online" -> "operational"
      "running" -> "operational"
      "paused" -> "temporarily stopped"
      "suspended" -> "temporarily stopped"
      "waiting" -> "temporarily stopped"
      _ -> "unknown status"
    end)
  end
  def main() do
    nil
  end
end
