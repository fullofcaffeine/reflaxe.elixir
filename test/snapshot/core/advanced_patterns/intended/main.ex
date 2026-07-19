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
      [_head | _tail] ->
        x = Enum.at(arr, 0)
        "single: #{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
      2 ->
        x = Enum.at(arr, 0)
        y = Enum.at(arr, 1)
        "pair: #{Reflaxe.Elixir.HaxeFloat.to_string(x)},#{Reflaxe.Elixir.HaxeFloat.to_string(y)}"
      3 ->
        x = Enum.at(arr, 0)
        y = Enum.at(arr, 1)
        z = Enum.at(arr, 2)
        "triple: #{Reflaxe.Elixir.HaxeFloat.to_string(x)},#{Reflaxe.Elixir.HaxeFloat.to_string(y)},#{Reflaxe.Elixir.HaxeFloat.to_string(z)}"
      4 ->
        first = Enum.at(arr, 0)
        second = Enum.at(arr, 1)
        third = Enum.at(arr, 2)
        fourth = Enum.at(arr, 3)
        "quad: #{Reflaxe.Elixir.HaxeFloat.to_string(first)},#{Reflaxe.Elixir.HaxeFloat.to_string(second)},#{Reflaxe.Elixir.HaxeFloat.to_string(third)},#{Reflaxe.Elixir.HaxeFloat.to_string(fourth)}"
      _ ->
        a = arr
        if (length(a) > 4) do
          "many: #{Reflaxe.Elixir.HaxeFloat.to_string(length(a))} elements"
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
        if (String.length(s) == 1) do
          "single char"
        else
          s = str
          if (String.length(s) > 10 and String.length(s) <= 20) do
            "medium"
          else
            s = str
            if (String.length(s) > 20), do: "long", else: "other"
          end
        end
    end)
  end
  def classify_number(n) do
    if (Reflaxe.Elixir.HaxeFloat.eq(n, 0)) do
      "zero"
    else
      x = n
      if (Reflaxe.Elixir.HaxeFloat.gt(x, 0) and Reflaxe.Elixir.HaxeFloat.lte(x, 1)) do
        "tiny"
      else
        x = n
        if (Reflaxe.Elixir.HaxeFloat.gt(x, 1) and Reflaxe.Elixir.HaxeFloat.lte(x, 10)) do
          "small"
        else
          x = n
          if (Reflaxe.Elixir.HaxeFloat.gt(x, 10) and Reflaxe.Elixir.HaxeFloat.lte(x, 100)) do
            "medium"
          else
            x = n
            if (Reflaxe.Elixir.HaxeFloat.gt(x, 100) and Reflaxe.Elixir.HaxeFloat.lte(x, 1000)) do
              "large"
            else
              x = n
              if (Reflaxe.Elixir.HaxeFloat.gt(x, 1000)) do
                "huge"
              else
                x = n
                if (Reflaxe.Elixir.HaxeFloat.lt(x, 0) and Reflaxe.Elixir.HaxeFloat.gte(x, -10)) do
                  "small negative"
                else
                  x = n
                  if (Reflaxe.Elixir.HaxeFloat.lt(x, -10)), do: "large negative", else: "unknown"
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
        true -> "basic user"
      end
    else
      "inactive"
    end
  end
  def match_matrix(matrix) do
    (case matrix do
      [] -> "empty matrix"
      [head | _tail] when length(head) == 1 ->
        x = Enum.at(head, 0)
        "single element: #{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
      [head | _tail] when length(m) == length(head) -> "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
      [_head | _tail] -> "non-square matrix"
      2 ->
        cond do
          length(Enum.at(matrix, 1)) == 2 ->
            c = Enum.at(g, 0)
            d = Enum.at(g, 1)
            b = Enum.at(g, 1)
            a = Enum.at(g, 0)
            "2x2 matrix: [[" <> Reflaxe.Elixir.HaxeFloat.to_string(a) <> "," <> Reflaxe.Elixir.HaxeFloat.to_string(b) <> "],[" <> Reflaxe.Elixir.HaxeFloat.to_string(c) <> "," <> Reflaxe.Elixir.HaxeFloat.to_string(d) <> "]]"
          true ->
            m = matrix
            if (length(m) == length(Enum.at(m, 0))) do
              "square matrix " <> Reflaxe.Elixir.HaxeFloat.to_string(length(m)) <> "x" <> Reflaxe.Elixir.HaxeFloat.to_string(length(m))
            else
              "non-square matrix"
            end
        end
      2 when length(m) == length(Enum.at(m, 0)) -> "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
      2 -> "non-square matrix"
      3 ->
        cond do
          length(Enum.at(matrix, 1)) == 3 ->
            if (length(Enum.at(matrix, 2)) == 3) do
              _h = Enum.at(g, 1)
              _i = Enum.at(g, 2)
              _a = Enum.at(g, 0)
              _b = Enum.at(g, 1)
              _c = Enum.at(g, 2)
              _f = Enum.at(g, 2)
              _e = Enum.at(g, 1)
              _d = Enum.at(g, 0)
              "3x3 matrix"
            else
              m = matrix
              if (length(m) == length(Enum.at(m, 0))) do
                "square matrix " <> Reflaxe.Elixir.HaxeFloat.to_string(length(m)) <> "x" <> Reflaxe.Elixir.HaxeFloat.to_string(length(m))
              else
                "non-square matrix"
              end
            end
          true ->
            m = matrix
            if (length(m) == length(Enum.at(m, 0))) do
              "square matrix " <> Reflaxe.Elixir.HaxeFloat.to_string(length(m)) <> "x" <> Reflaxe.Elixir.HaxeFloat.to_string(length(m))
            else
              "non-square matrix"
            end
        end
      3 when length(m) == length(Enum.at(m, 0)) -> "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
      3 -> "non-square matrix"
      _ ->
        m = matrix
        if (length(m) == length(Enum.at(m, 0))) do
          "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
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
          false when age >= 13 and age < 18 -> "teen without permission"
          false when age >= 18 and age < 21 -> "young adult"
          false when age >= 21 and age < 65 -> "adult"
          false when age >= 65 -> "senior"
          false -> "unknown"
          true when age >= 13 and age < 18 -> "teen with permission"
          true when age >= 18 and age < 21 -> "young adult"
          true when age >= 21 and age < 65 -> "adult"
          true when age >= 65 -> "senior"
          true -> "unknown"
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
      "string: \"#{Reflaxe.Elixir.HaxeFloat.to_string(v)}\""
    else
      v = value
      if (Std.is(v, Int)) do
        "integer: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
      else
        v = value
        if (Std.is(v, Float)) do
          "float: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
        else
          v = value
          if (Std.is(v, Bool)) do
            "boolean: #{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
          else
            v = value
            cond do
              Std.is(v, Array) -> "array of length " <> Reflaxe.Elixir.HaxeFloat.to_string(length(v))
              Reflaxe.Elixir.HaxeFloat.eq(value, nil) -> "null value"
              true -> "unknown type"
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
    cond_value = (case Enum.find_index(primary_colors, fn item -> item == c end) do
      nil -> -1
      index -> index
    end)
    if (cond_value >= 0) do
      "primary color"
    else
      c = color
      cond_value = (case Enum.find_index(secondary_colors, fn item -> item == c end) do
        nil -> -1
        index -> index
      end)
      if (cond_value >= 0) do
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
