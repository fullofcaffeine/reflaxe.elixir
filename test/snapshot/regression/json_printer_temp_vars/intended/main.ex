defmodule Main do
  def test_temp_variable_scoping() do
    obj = %{:finite_number => 42.5, :infinite_number => 1 / 0, :string_value => "test"}
    result = JsonPrinter.print(obj, nil, nil)
    Log.trace("Serialized JSON: " <> result, %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testTempVariableScoping"})
  end
  def test_ternary_with_temp_vars() do
    value = 42.5
    result = if (value == value && value != 1 / 0 && value != 1 / 0 * -1) do
  Std.string(value)
else
  "null"
end
    Log.trace("Ternary result: " <> result, %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testTernaryWithTempVars"})
  end
  def main() do
    Log.trace("=== Testing JsonPrinter Temp Variable Scoping ===", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "main"})
    test_temp_variable_scoping()
    Log.trace("\n=== Testing Ternary with Temp Variables ===", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "main"})
    test_ternary_with_temp_vars()
  end
end