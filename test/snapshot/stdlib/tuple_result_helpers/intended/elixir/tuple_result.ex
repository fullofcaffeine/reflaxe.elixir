defmodule TupleResult do
  def is_ok(result) do
    result._0 == "ok"
  end
  def is_error(result) do
    result._0 == "error"
  end
  def unwrap(result) do
    if (result._0 != "ok") do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Expected ok tuple, got " <> result._0, nil, nil)]
    end
    result._1
  end
  def unwrap_or(result, default_value) do
    if (result._0 == "ok"), do: result._1, else: default_value
  end
  def map_ok(result, fn_param) do
    if (result._0 == "ok"), do: {"ok", fn_param.(result._1)}, else: result
  end
  def map_error(result, fn_param) do
    if (result._0 == "error"), do: {"error", fn_param.(result._1)}, else: result
  end
end
