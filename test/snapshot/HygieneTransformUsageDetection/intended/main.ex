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
    Date.from_unix(Std.int(t), "millisecond")
  end

  defp deep_nesting(t) do
    v = ceil(if t < 0, do: -t, else: t)
    floor(v)
  end

  defp mixed_ops(t, u) do
    if t > 0 do
      Log.trace(t, %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "mixedOps"})
      t + u
    end
    u
  end

  defp write_only(input) do
    _x = 0
    _x = 2
    input * 2
  end

  defp shadowing() do
    _t = 1
    process(2)
  end

  defp used_param(t) do
    t + 1
  end

  defp unused_param(_t) do
    1
  end

  defp for_loop_test(arr) do
    # Simple sum using Enum.sum
    Enum.sum(arr)
  end

  defp string_concat(t) do
    "Value: #{t}"
  end

  defp field_vs_ident(obj, _t) do
    _t = 1
    Log.trace(obj.t, %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "fieldVsIdent"})
  end

  defp multiple_unused(_a, _b, _c) do
    42
  end

  defp process(value) do
    value * 2
  end

  defp test_nested_call_argument() do
    _result = from_time(1234567890)
    Log.trace("Nested call test passed", %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testNestedCallArgument"})
  end

  defp test_deep_nesting() do
    _result = deep_nesting(-5)
    Log.trace("Deep nesting test passed", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testDeepNesting"})
  end

  defp test_mixed_operations() do
    _result = mixed_ops(5, 3)
    Log.trace("Mixed operations test passed", %{:file_name => "Main.hx", :line_number => 117, :class_name => "Main", :method_name => "testMixedOperations"})
  end

  defp test_write_only() do
    _result = write_only(10)
    Log.trace("Write-only test passed", %{:file_name => "Main.hx", :line_number => 122, :class_name => "Main", :method_name => "testWriteOnly"})
  end

  defp test_shadowing() do
    _result = shadowing()
    Log.trace("Shadowing test passed", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testShadowing"})
  end

  defp test_function_params() do
    _r1 = used_param(5)
    _r2 = unused_param(5)
    Log.trace("Function params test passed", %{:file_name => "Main.hx", :line_number => 133, :class_name => "Main", :method_name => "testFunctionParams"})
  end

  defp test_for_loop() do
    _result = for_loop_test([1, 2, 3])
    Log.trace("For loop test passed", %{:file_name => "Main.hx", :line_number => 138, :class_name => "Main", :method_name => "testForLoop"})
  end

  defp test_string_concatenation() do
    _result = string_concat("test")
    Log.trace("String concatenation test passed", %{:file_name => "Main.hx", :line_number => 143, :class_name => "Main", :method_name => "testStringConcatenation"})
  end

  defp test_field_vs_ident() do
    field_vs_ident(%{}, 5)
    Log.trace("Field vs ident test passed", %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testFieldVsIdent"})
  end

  defp test_unused_parameters() do
    _result = multiple_unused(1, "test", 3.14)
    Log.trace("Multiple unused test passed", %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testUnusedParameters"})
  end
end