defmodule Main do
  def main() do
    ok_result = {:ok, "created"}
    error_result = {:error, "invalid"}
    if (not match?({:ok, _}, ok_result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ok tuple did not match"]
    end
    if (not match?({:error, _}, error_result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "error tuple did not match"]
    end
    if (match?({:error, _}, ok_result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ok tuple matched error"]
    end
    if (match?({:ok, _}, error_result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "error tuple matched ok"]
    end
    ok_value = elem(ok_result, 1)
    error_reason = elem(error_result, 1)
    ok_value_matches = ok_value == "created"
    error_reason_matches = error_reason == "invalid"
    if (not ok_value_matches) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ok tuple value was not extracted"]
    end
    if (not error_reason_matches) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "error tuple reason was not extracted"]
    end
  end
end
