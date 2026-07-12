defmodule Main do
  def main() do
    values = TailValues.new()
    if (apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :int_literal, [values, 9]) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "int tail value lost"]
    end
    if (apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :bool_literal, [values]) != false) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "bool tail value lost"]
    end
    if (apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :string_literal, [values]) != "tail") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "string tail value lost"]
    end
    float_ok = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :float_literal, [values]) == 1.5
    if (not float_ok) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "float tail value lost"]
    end
    if (not Kernel.is_nil(apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :null_literal, [values]))) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "null tail value lost"]
    end
    array_value = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :array_literal, [values])
    if (length(array_value) != 3 or Enum.at(array_value, 0) != 1 or Enum.at(array_value, 2) != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "array tail value lost"]
    end
    object_value = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :object_literal, [values])
    if (object_value.value != 7) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "object tail value lost"]
    end
    tuple_value = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :tuple_literal, [values])
    tuple_ok = is_tuple(tuple_value) and elem(tuple_value, 0) == "tuple" and elem(tuple_value, 1) == 4
    if (not tuple_ok) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "tuple tail value lost"]
    end
    if (apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :local_value, [values, 11]) != 11) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "local tail value lost"]
    end
    if (apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :call_value, [values]) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "call tail value lost"]
    end
    if (apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :branch_value, [values, true]) != 1 or apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :branch_value, [values, false]) != 2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "branch tail value lost"]
    end
  end
end
