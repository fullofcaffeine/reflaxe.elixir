defmodule Main do
  def main() do
    Main.test_basic_ternary()
    Main.test_nested_ternary()
    Main.test_ternary_in_function()
  end
  defp test_basic_ternary() do
    config = %{:name => "test"}
    id = if (config != nil), do: config.id, else: "default"
    Log.trace("ID: " + id, %{:fileName => "Main.hx", :lineNumber => 14, :className => "Main", :methodName => "testBasicTernary"})
  end
  defp test_nested_ternary() do
    a = 5
    b = 10
    result = if (a > 0) do
  if (b > 0), do: "both positive", else: "a positive"
else
  "a not positive"
end
    Log.trace("Result: " + result, %{:fileName => "Main.hx", :lineNumber => 22, :className => "Main", :methodName => "testNestedTernary"})
  end
  defp test_ternary_in_function() do
    module = "MyModule"
    args = [1, 2, 3]
    id = nil
    spec = Main.create_spec(module, args, id)
    Log.trace("Spec: " + Std.string(spec), %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testTernaryInFunction"})
  end
  defp create_spec(module, args, id) do
    actual_id = if (id != nil), do: id, else: module
    %{:id => actual_id, :module => module, :args => args}
  end
end