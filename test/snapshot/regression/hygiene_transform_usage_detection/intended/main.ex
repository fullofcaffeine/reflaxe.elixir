defmodule Main do
  def main() do
    _ = test_nested_call_argument()
    _ = test_deep_nesting()
    _ = test_mixed_operations()
    _ = test_write_only()
    _ = test_shadowing()
    _ = test_function_params()
    _ = test_for_loop()
    _ = test_string_concatenation()
    _ = test_field_vs_ident()
    _ = test_unused_parameters()
  end
  defp from_time(t) do
    Date.from_unix(trunc(t), "millisecond")
  end
  defp deep_nesting(t) do
    v = (ceil(if (t < 0) do
  -t
else
  t
end))
    floor(v)
  end
  defp mixed_ops(t, u) do
    if (t > 0), do: t + u, else: u
  end
  defp write_only(input) do
    input * 2
  end
  defp shadowing() do
    t = 2
    _ = process(t)
  end
  defp used_param(t) do
    t + 1
  end
  defp unused_param(_) do
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
  defp field_vs_ident(obj, _) do
    _ = Map.put(obj, :t, 1)
    nil
  end
  defp multiple_unused(_, _, _) do
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
    _ = field_vs_ident(%{}, 5)
    nil
  end
  defp test_unused_parameters() do
    _result = multiple_unused(1, "test", 3.14)
    nil
  end
end
