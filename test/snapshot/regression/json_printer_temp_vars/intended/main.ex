defmodule Main do
  def test_temp_variable_scoping() do
    obj = %{:finiteNumber => 42.5, :infiniteNumber => Math.POSITIVE_INFINITY, :stringValue => "test"}
    result = JsonPrinter.print(obj, nil, nil)
    Log.trace("Serialized JSON: " + result, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testTempVariableScoping"})
  end
  def test_ternary_with_temp_vars() do
    value = 42.5
    result = if (Math.is_finite(value)) do
  Std.string(value)
else
  "null"
end
    Log.trace("Ternary result: " + result, %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "testTernaryWithTempVars"})
  end
  def main() do
    Log.trace("=== Testing JsonPrinter Temp Variable Scoping ===", %{:fileName => "Main.hx", :lineNumber => 45, :className => "Main", :methodName => "main"})
    Main.test_temp_variable_scoping()
    Log.trace("\n=== Testing Ternary with Temp Variables ===", %{:fileName => "Main.hx", :lineNumber => 48, :className => "Main", :methodName => "main"})
    Main.test_ternary_with_temp_vars()
  end
end