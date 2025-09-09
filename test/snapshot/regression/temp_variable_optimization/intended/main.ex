defmodule Main do
  def main() do
    test_basic_ternary()
    test_nested_ternary()
    test_ternary_in_function()
  end
  defp test_basic_ternary() do
    config = %{:name => "test"}
    id = if (config != nil), do: config.id, else: "default"
    Log.trace("ID: " <> id, %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "testBasicTernary"})
  end
  defp test_nested_ternary() do
    a = 5
    b = 10
    result = if (a > 0) do
  if (b > 0), do: "both positive", else: "a positive"
else
  "a not positive"
end
    Log.trace("Result: " <> result, %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "testNestedTernary"})
  end
  defp test_ternary_in_function() do
    module = "MyModule"
    args = [1, 2, 3]
    id = nil
    spec = create_spec(module, args, id)
    Log.trace("Spec: " <> Std.string(spec), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testTernaryInFunction"})
  end
  defp create_spec(module, args, id) do
    actual_id = if (id != nil), do: id, else: module
    %{:id => actual_id, :module => module, :args => args}
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()