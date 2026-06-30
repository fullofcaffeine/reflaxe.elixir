defmodule Main do
  def main() do
    event = {:select, 42}
    state = {:open}
    (case event do
      {:select, id} ->
        cond do
          id <= 0 -> raise Reflaxe.Elixir.HaxeThrow, [value: "invalid id"]
          true -> nil
        end
      {:clear} -> nil
    end)
    (case state do
      {:open} -> nil
      {:closed} -> raise Reflaxe.Elixir.HaxeThrow, [value: "unexpected"]
    end)
  end
end
