defmodule Main do
  def test_temp_variable_scoping() do
    obj = %{:finite_number => 42.5, :infinite_number => 1.79769313486231571e+308, :string_value => "test"}
    _result = JsonPrinter.print(obj, nil, nil)
    nil
  end
  def test_ternary_with_temp_vars() do
    value = 42.5
    _result = if (value == value and value != 1.79769313486231571e+308 and value != -1.79769313486231571e+308), do: inspect(value), else: "null"
    nil
  end
  def main() do
    _ = test_temp_variable_scoping()
    _ = test_ternary_with_temp_vars()
  end
end
