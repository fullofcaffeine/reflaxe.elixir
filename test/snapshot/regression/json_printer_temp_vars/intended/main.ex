defmodule Main do
  def test_temp_variable_scoping() do
    obj = %{:finite_number => 42.5, :infinite_number => 1 / 0, :string_value => "test"}
    result = replacer = nil
    space = nil
    
          replacer = replacer
          pretty = space != nil

          transform = fn v ->
            cond do
              is_map(v) ->
                if is_function(replacer, 2) do
                  v
                  |> Enum.map(fn {k, val} -> {k, transform.(replacer.(to_string(k), val))} end)
                  |> Enum.into(%{})
                else
                  v
                  |> Enum.map(fn {k, val} -> {k, transform.(val)} end)
                  |> Enum.into(%{})
                end
              is_list(v) -> Enum.map(v, transform)
              true ->
                if is_function(replacer, 2), do: replacer.(nil, v), else: v
            end
          end

          Jason.encode!(transform.(obj), pretty: pretty)
        
    _ = Log.trace("Serialized JSON: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testTempVariableScoping"})
  end
  def test_ternary_with_temp_vars() do
    value = 42.5
    result = if (value == value and value != 1 / 0 and value != 1 / 0 * -1), do: inspect(value), else: "null"
    _ = Log.trace("Ternary result: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testTernaryWithTempVars"})
  end
  def main() do
    _ = Log.trace("=== Testing JsonPrinter Temp Variable Scoping ===", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "main"})
    _ = test_temp_variable_scoping()
    _ = Log.trace("\n=== Testing Ternary with Temp Variables ===", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "main"})
    _ = test_ternary_with_temp_vars()
  end
end
