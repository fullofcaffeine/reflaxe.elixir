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
  @doc "Generated from Haxe testTempVariableScoping"
  def test_temp_variable_scoping() do
    obj = %{"finiteNumber" => 42.5, "infiniteNumber" => Math.p_o_s_i_t_i_v_e__i_n_f_i_n_i_t_y, "stringValue" => "test"}

    result = JsonPrinter.print(obj, nil, nil)

    Log.trace("Serialized JSON: " <> result, %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "testTempVariableScoping"})
  end

  @doc "Generated from Haxe testTernaryWithTempVars"
  def test_ternary_with_temp_vars() do
    temp_string = nil

    value = 42.5

    temp_string = nil

    if Math.is_finite(value), do: temp_string = Std.string(value), else: temp_string = "null"

    Log.trace("Ternary result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "testTernaryWithTempVars"})
  end

  @doc "Generated from Haxe main"
  def main() do
    temp_variable_scoping = nil
    temp_vars = nil

    Log.trace("=== Testing JsonPrinter Temp Variable Scoping ===", %{"fileName" => "Main.hx", "lineNumber" => 45, "className" => "Main", "methodName" => "main"})

    Main.test_temp_variable_scoping()

    Log.trace("\n=== Testing Ternary with Temp Variables ===", %{"fileName" => "Main.hx", "lineNumber" => 48, "className" => "Main", "methodName" => "main"})

    Main.test_ternary_with_temp_vars()
  end

end
