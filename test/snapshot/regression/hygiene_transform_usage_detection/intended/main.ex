defmodule Main do
  def main() do
    test_nested_call_argument()
    test_deep_nesting()
    test_mixed_operations()
    test_write_only()
    test_shadowing()
    test_function_params()
    test_for_loop()
    test_string_concatenation()
    test_field_vs_ident()
    test_unused_parameters()
  end
  defp from_time(t) do
    Date.from_unix(trunc(t), "millisecond")
  end
  defp deep_nesting(t) do
    v = Reflaxe.Elixir.HaxeFloat.abs(t)
    v = Reflaxe.Elixir.HaxeFloat.ceil_int(v)
    Reflaxe.Elixir.HaxeFloat.floor_int(v)
  end
  defp mixed_ops(t, u) do
    if (t > 0), do: t + u, else: u
  end
  defp write_only(input) do
    input * 2
  end
  defp shadowing() do
    t = 2
    process(t)
  end
  defp used_param(t) do
    t + 1
  end
  defp unused_param(_t) do
    1
  end
  defp for_loop_test(arr) do
    sum = 0
    _g = 0
    sum = Enum.reduce(arr, sum, fn i, sum_acc -> sum_acc + i end)
    sum
  end
  defp string_concat(t) do
    "Value: #{t}"
  end
  defp field_vs_ident(obj, _t) do
    _ = Map.put(obj, :t, 1)
    nil
  end
  defp multiple_unused(_a, _b, _c) do
    42
  end
  defp process(value) do
    value * 2
  end
  defp test_nested_call_argument() do
    _result = from_time(1234567890)
    nil
  end
  defp test_deep_nesting() do
    _result = deep_nesting(-5)
    nil
  end
  defp test_mixed_operations() do
    _result = mixed_ops(5, 3)
    nil
  end
  defp test_write_only() do
    _result = write_only(10)
    nil
  end
  defp test_shadowing() do
    _result = shadowing()
    nil
  end
  defp test_function_params() do
    _ = used_param(5)
    _ = unused_param(5)
    nil
  end
  defp test_for_loop() do
    _result = for_loop_test([1, 2, 3])
    nil
  end
  defp test_string_concatenation() do
    _result = string_concat("test")
    nil
  end
  defp test_field_vs_ident() do
    field_vs_ident(%{}, 5)
    nil
  end
  defp test_unused_parameters() do
    _result = multiple_unused(1, "test", 3.14)
    nil
  end
end
