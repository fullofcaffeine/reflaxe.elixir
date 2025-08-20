defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test for JsonPrinter temp variable scoping issue
     *
     * This test reproduces the issue where temp variables are assigned inside
     * if expressions, creating local scope that makes them inaccessible outside.
     *
     * Pattern: if (cond), do: temp_var = val1, else: temp_var = val2
     * Issue: temp_var is not accessible after the if expression
     * Fix: Should generate: var = if (cond), do: val1, else: val2
  """

  # Static functions
  @doc "Function test_temp_variable_scoping"
  @spec test_temp_variable_scoping() :: nil
  def test_temp_variable_scoping() do
    obj = %{"finiteNumber" => 42.5, "infiniteNumber" => Math.p_o_s_i_t_i_v_e__i_n_f_i_n_i_t_y, "stringValue" => "test"}
    result = JsonPrinter.print(obj, nil, nil)
    Log.trace("Serialized JSON: " <> result, %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "testTempVariableScoping"})
  end

  @doc "Function test_ternary_with_temp_vars"
  @spec test_ternary_with_temp_vars() :: nil
  def test_ternary_with_temp_vars() do
    value = 42.5
    temp_string = nil
    temp_string = if (Math.isFinite(value)), do: Std.string(value), else: "null"
    Log.trace("Ternary result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "testTernaryWithTempVars"})
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== Testing JsonPrinter Temp Variable Scoping ===", %{"fileName" => "Main.hx", "lineNumber" => 45, "className" => "Main", "methodName" => "main"})
    Main.testTempVariableScoping()
    Log.trace("\n=== Testing Ternary with Temp Variables ===", %{"fileName" => "Main.hx", "lineNumber" => 48, "className" => "Main", "methodName" => "main"})
    Main.testTernaryWithTempVars()
  end

end
