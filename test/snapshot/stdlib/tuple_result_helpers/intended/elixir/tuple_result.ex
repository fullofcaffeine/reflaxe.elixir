defmodule TupleResult do
  def is_ok(result) do
    elem(result, 0) == "ok"
  end
  def is_error(result) do
    elem(result, 0) == "error"
  end
  def unwrap(result) do
    if (elem(result, 0) != "ok") do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Expected ok tuple, got " <> elem(result, 0), nil, nil)]
    end
    _ = elem(result, 1)
  end
  def unwrap_or(result, default_value) do
    if (elem(result, 0) == "ok"), do: elem(result, 1), else: default_value
  end
  def map_ok(result, fn_param) do
    if (elem(result, 0) == "ok"), do: {"ok", fn_param.(elem(result, 1))}, else: result
  end
  def map_error(result, fn_param) do
    if (elem(result, 0) == "error"), do: {"error", fn_param.(elem(result, 1))}, else: result
  end
end
