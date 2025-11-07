defmodule Main do
  def main() do
    _ = test_basic_ternary()
    _ = test_nested_ternary()
    _ = test_ternary_in_function()
  end
  defp test_basic_ternary() do
    config = %{:name => "test"}
    id = if (not Kernel.is_nil(config)) do
      Map.get(config, :id)
    else
      "default"
    end
    _ = Log.trace("ID: #{(fn -> id end).()}", %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "testBasicTernary"})
  end
  defp test_nested_ternary() do
    a = 5
    b = 10
    result = if (a > 0) do
      if (b > 0), do: "both positive", else: "a positive"
    else
      "a not positive"
    end
    _ = Log.trace("Result: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "testNestedTernary"})
  end
  defp test_ternary_in_function() do
    module = "MyModule"
    args = [1, 2, 3]
    id = nil
    spec = create_spec(module, args, id)
    _ = Log.trace("Spec: #{(fn -> inspect(spec) end).()}", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testTernaryInFunction"})
  end
  defp create_spec(module, args, id) do
    actual_id = if (not Kernel.is_nil(id)), do: id, else: module
    %{:id => actual_id, :module => module, :args => args}
  end
end
