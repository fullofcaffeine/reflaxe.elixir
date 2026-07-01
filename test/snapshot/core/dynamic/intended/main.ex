defmodule Main do
  def dynamic_vars() do
    _dyn = fn x -> x * 2 end
    nil
  end
  def dynamic_field_access() do
    obj = %{name: "Alice", age: 25, greet: fn -> "Hello!" end}
    _ = Map.put(obj, :city, "New York")
    nil
  end
  def dynamic_functions() do
    _fn_ = fn a, b -> a + b end
    _ = fn s -> String.upcase(s) end
    _var_args = fn args ->
      sum = 0
      _g = 0
      Enum.reduce(args, sum, fn arg, sum_acc -> Reflaxe.Elixir.HaxeFloat.add(sum_acc, arg) end)
    end
    nil
  end
  def type_checking() do
    value = 42
    if (Std.is(value, Int)), do: nil
    value = "Hello"
    if (Std.is(value, String)), do: nil
    value = [1, 2, 3]
    if (Std.is(value, Array)), do: nil
    num = "123"
    _int_value = (case Integer.parse(num) do
      {num, _} -> num
      :error -> nil
    end)
    _float_value = Reflaxe.Elixir.HaxeFloat.parse("3.14")
    nil
  end
  def dynamic_generics(value) do
    value
  end
  def dynamic_collections() do
    dyn_array = [1, "two", 3, true, %{x: 10}]
    _g = 0
    _ = Enum.each(dyn_array, fn _ -> nil end)
    dyn_obj = %{}
    _ = dyn_obj |> Map.put(:field1, "value1") |> Map.put(:field2, 42) |> Map.put(:field3, [1, 2, 3])
    nil
  end
  def process_dynamic(value) do
    cond do
      Reflaxe.Elixir.HaxeFloat.eq(value, nil) -> "null"
      Std.is(value, Bool) -> "Bool: " <> Reflaxe.Elixir.HaxeFloat.to_string(value)
      Std.is(value, Int) -> "Int: " <> Reflaxe.Elixir.HaxeFloat.to_string(value)
      Std.is(value, Float) -> "Float: " <> Reflaxe.Elixir.HaxeFloat.to_string(value)
      Std.is(value, String) -> "String: " <> Reflaxe.Elixir.HaxeFloat.to_string(value)
      Std.is(value, Array) -> "Array of length: " <> Reflaxe.Elixir.HaxeFloat.to_string(length(value))
      true -> "Unknown type"
    end
  end
  def dynamic_method_calls() do
    obj = %{}
    obj = obj |> Map.put(:value, 10) |> Map.put(:increment, fn ->
  Reflaxe.Elixir.HaxeFloat.add(((case obj do
    dyn_obj ->
      (case Map.fetch(dyn_obj, "value") do
        {:ok, dyn_value} -> dyn_value
        _ ->
          Map.get(dyn_obj, :value)
      end)
  end)), 1)
end) |> Map.put(:get_value, fn ->
  (case obj do
    dyn_obj ->
      (case Map.fetch(dyn_obj, "value") do
        {:ok, dyn_value} -> dyn_value
        _ ->
          Map.get(dyn_obj, :value)
      end)
  end)
end)
    _ = (case obj do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "increment") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :increment)
    end)
end).()
    method_name = "increment"
    _ = Reflect.call_method(obj, ((case {obj, method_name} do
  {reflect_obj, reflect_field} ->
    (case Map.fetch(reflect_obj, reflect_field) do
      {:ok, reflect_value} -> reflect_value
      _ ->
        (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
          nil -> nil
          reflect_atom ->
            Map.get(reflect_obj, reflect_atom)
        end)
    end)
end)), [])
    nil
  end
  def main() do
    _ = dynamic_vars()
    _ = dynamic_field_access()
    _ = dynamic_functions()
    _ = type_checking()
    _ = dynamic_collections()
    _ = dynamic_method_calls()
    _str = dynamic_generics("Hello from dynamic")
    nil
  end
end
