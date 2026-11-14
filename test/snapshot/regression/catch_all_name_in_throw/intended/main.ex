defmodule Main do
  def main() do

  end
  def require_now(next) do
    g = next.()
    (case g do
      {:now} -> nil
      _ ->
        other = g
        raise Reflaxe.Elixir.HaxeThrow, [value: "expected Now, got " <> Reflaxe.Elixir.HaxeFloat.enum_to_string(NextEvent, other)]
    end)
    "now"
  end
end
