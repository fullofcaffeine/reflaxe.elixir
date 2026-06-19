defmodule Main do
  def test_temp_variable_scoping() do
    obj = %{:finite_number => 42.5, :infinite_number => Reflaxe.Elixir.HaxeFloat.positive_infinity(), :string_value => "test"}
    _result = JsonPrinter.print(obj, nil, nil)
    nil
  end
  def test_ternary_with_temp_vars() do
    value = 42.5
    _result = if (Reflaxe.Elixir.HaxeFloat.is_finite(value)) do
      Reflaxe.Elixir.HaxeFloat.to_string(value)
    else
      "null"
    end
    nil
  end
  def main() do
    _ = test_temp_variable_scoping()
    _ = test_ternary_with_temp_vars()
  end
end
