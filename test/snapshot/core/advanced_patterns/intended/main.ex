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
    (case length(arr) do
      0 -> "empty"
      1 ->
        array_read_node_0 = Enum.at(arr, 0)
        x = array_read_node_0
        "single: #{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
      2 ->
        array_read_node_1 = Enum.at(arr, 0)
        array_read_node_2 = Enum.at(arr, 1)
        x = array_read_node_1
        y = array_read_node_2
        "pair: #{Reflaxe.Elixir.HaxeFloat.to_string(x)},#{Reflaxe.Elixir.HaxeFloat.to_string(y)}"
      3 ->
        array_read_node_3 = Enum.at(arr, 0)
        array_read_node_4 = Enum.at(arr, 1)
        array_read_node_5 = Enum.at(arr, 2)
        x = array_read_node_3
        y = array_read_node_4
        z = array_read_node_5
        "triple: #{Reflaxe.Elixir.HaxeFloat.to_string(x)},#{Reflaxe.Elixir.HaxeFloat.to_string(y)},#{Reflaxe.Elixir.HaxeFloat.to_string(z)}"
      4 ->
        array_read_node_6 = Enum.at(arr, 0)
        array_read_node_7 = Enum.at(arr, 1)
        array_read_node_8 = Enum.at(arr, 2)
        array_read_node_9 = Enum.at(arr, 3)
        first = array_read_node_6
        second = array_read_node_7
        third = array_read_node_8
        fourth = array_read_node_9
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
      _ ->
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
    (case length(matrix) do
      0 -> "empty matrix"
      1 ->
        array_read_node_10 = Enum.at(matrix, 0)
        if (length(array_read_node_10) == 1) do
          array_read_node_11 = Enum.at(array_read_node_10, 0)
          x = array_read_node_11
          "single element: #{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
        else
          m = matrix
          if (length(m) == length(Enum.at(m, 0))) do
            "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
          else
            "non-square matrix"
          end
        end
      2 ->
        array_read_node_12 = Enum.at(matrix, 0)
        array_read_node_13 = Enum.at(matrix, 1)
        if (length(array_read_node_12) == 2) do
          array_read_node_14 = Enum.at(array_read_node_12, 0)
          array_read_node_15 = Enum.at(array_read_node_12, 1)
          if (length(array_read_node_13) == 2) do
            array_read_node_16 = Enum.at(array_read_node_13, 0)
            array_read_node_17 = Enum.at(array_read_node_13, 1)
            c = array_read_node_16
            d = array_read_node_17
            b = array_read_node_15
            a = array_read_node_14
            "2x2 matrix: [[#{Reflaxe.Elixir.HaxeFloat.to_string(a)},#{Reflaxe.Elixir.HaxeFloat.to_string(b)}],[#{Reflaxe.Elixir.HaxeFloat.to_string(c)},#{Reflaxe.Elixir.HaxeFloat.to_string(d)}]]"
          else
            m = matrix
            if (length(m) == length(Enum.at(m, 0))) do
              "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
            else
              "non-square matrix"
            end
          end
        else
          m = matrix
          if (length(m) == length(Enum.at(m, 0))) do
            "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
          else
            "non-square matrix"
          end
        end
      3 ->
        array_read_node_18 = Enum.at(matrix, 0)
        array_read_node_19 = Enum.at(matrix, 1)
        array_read_node_20 = Enum.at(matrix, 2)
        if (length(array_read_node_18) == 3) do
          array_read_node_21 = Enum.at(array_read_node_18, 0)
          array_read_node_22 = Enum.at(array_read_node_18, 1)
          array_read_node_23 = Enum.at(array_read_node_18, 2)
          if (length(array_read_node_19) == 3) do
            array_read_node_24 = Enum.at(array_read_node_19, 0)
            array_read_node_25 = Enum.at(array_read_node_19, 1)
            array_read_node_26 = Enum.at(array_read_node_19, 2)
            if (length(array_read_node_20) == 3) do
              _array_read_node_27 = Enum.at(array_read_node_20, 0)
              array_read_node_28 = Enum.at(array_read_node_20, 1)
              array_read_node_29 = Enum.at(array_read_node_20, 2)
              _h = array_read_node_28
              _i = array_read_node_29
              _a = array_read_node_21
              _b = array_read_node_22
              _c = array_read_node_23
              _f = array_read_node_26
              _e = array_read_node_25
              _d = array_read_node_24
              "3x3 matrix"
            else
              m = matrix
              if (length(m) == length(Enum.at(m, 0))) do
                "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
              else
                "non-square matrix"
              end
            end
          else
            m = matrix
            if (length(m) == length(Enum.at(m, 0))) do
              "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
            else
              "non-square matrix"
            end
          end
        else
          m = matrix
          if (length(m) == length(Enum.at(m, 0))) do
            "square matrix #{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}x#{Reflaxe.Elixir.HaxeFloat.to_string(length(m))}"
          else
            "non-square matrix"
          end
        end
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
          false ->
            a = age
            if (a >= 13 and a < 18) do
              "teen without permission"
            else
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
            end
          true ->
            a = age
            if (a >= 13 and a < 18) do
              "teen with permission"
            else
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
            end
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
              Std.is(v, Array) ->
                "array of length " <> Reflaxe.Elixir.HaxeFloat.to_string((fn
                  dyn_obj when is_binary(dyn_obj) ->
                    String.length(dyn_obj)
                  dyn_obj when is_list(dyn_obj) ->
                    length(dyn_obj)
                  dyn_obj ->
                    (case Map.fetch(dyn_obj, "length") do
                      {:ok, dyn_value} -> dyn_value
                      _ ->
                        Map.get(dyn_obj, :length)
                    end)
                end).(v))
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
    if (((case Enum.find_index(primary_colors, fn item -> item == c end) do
      nil -> -1
      index -> index
    end) >= 0)) do
      "primary color"
    else
      c = color
      if (((case Enum.find_index(secondary_colors, fn item -> item == c end) do
        nil -> -1
        index -> index
      end) >= 0)) do
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
  defp expect(actual, expected) do
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected \"" <> expected <> "\", got \"" <> actual <> "\""]
    end
  end
  def main() do
    expect(match_simple_value(-5), "negative")
    expect(match_simple_value(150), "large")
    expect(classify_string("x"), "single char")
    expect(process_array([]), "empty")
    expect(process_array([7]), "single: 7")
    expect(process_array([7, 8]), "pair: 7,8")
    expect(process_array([7, 8, 9]), "triple: 7,8,9")
    expect(process_array([1, 2, 3, 4]), "quad: 1,2,3,4")
    expect(process_array([1, 2, 3, 4, 5]), "many: 5 elements")
    expect(match_matrix([]), "empty matrix")
    expect(match_matrix([[7]]), "single element: 7")
    expect(match_matrix([[1, 2], [3, 4]]), "2x2 matrix: [[1,2],[3,4]]")
    expect(match_matrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]]), "3x3 matrix")
    expect(match_matrix([[1, 2]]), "non-square matrix")
    nil
  end
end
