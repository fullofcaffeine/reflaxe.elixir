defmodule Main do
  def dynamic_vars() do
    dyn = 42
    dyn = "Hello"
    dyn = [1, 2, 3]
    dyn = %{:name => "John", :age => 30}
    dyn = fn x -> x * 2 end
    nil
  end
  def dynamic_field_access() do
    obj = %{:name => "Alice", :age => 25, :greet => fn -> "Hello!" end}
    obj = Map.put(obj, "city", "New York")
    nil
  end
  def dynamic_functions() do
    fn_ = fn a, b -> a + b end
    fn_ = fn s -> String.upcase(s) end
    var_args = fn args ->
      g = 0
      _ = Enum.each(0..(length(args) - 1), (fn -> fn g ->
        arg = args[g]
        g + 1
        sum = sum + arg
      end end).())
    end
    nil
  end
  def type_checking() do
    value = 42
    if (MyApp.Std.is(value, Int)), do: nil
    value = "Hello"
    if (MyApp.Std.is(value, String)), do: nil
    value = [1, 2, 3]
    if (MyApp.Std.is(value, Array)), do: nil
    num = "123"
    int_value = String.to_integer(num)
    float_value = String.to_float("3.14")
    nil
  end
  def dynamic_generics(value) do
    value
  end
  def dynamic_collections() do
    dyn_obj = dyn_obj |> Map.put("field1", "value1") |> Map.put("field2", 42) |> Map.put("field3", [1, 2, 3])
  end
  def process_dynamic(value) do
    cond do
      value == nil -> "null"
      Std.is(value, Bool) -> "Bool: " <> inspect(value)
      Std.is(value, Int) -> "Int: " <> inspect(value)
      Std.is(value, Float) -> "Float: " <> inspect(value)
      Std.is(value, String) -> "String: " <> inspect(value)
      Std.is(value, Array) -> "Array of length: " <> inspect(Map.get(value, :length))
      :true -> "Unknown type"
    end
  end
  def dynamic_method_calls() do
    obj = obj |> Map.put("value", 10) |> Map.put("increment", fn -> Map.get(obj, :value) + 1 end) |> Map.put("get_value", fn -> Map.get(obj, :value) end)
  end
  def main() do
    _ = dynamic_vars()
    _ = dynamic_field_access()
    _ = dynamic_functions()
    _ = type_checking()
    _ = dynamic_collections()
    _ = dynamic_method_calls()
    str = dynamic_generics("Hello from dynamic")
    nil
  end
end
