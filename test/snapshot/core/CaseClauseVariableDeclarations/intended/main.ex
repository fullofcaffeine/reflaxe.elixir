defmodule Main do
  defp test_function_body() do
    fn_ = fn x ->
      doubled = x * 2
      tripled = x * 3
      doubled + tripled
    end
    fn_.(5)
  end
  defp perform_risky_operation() do
    if (Reflaxe.Elixir.HaxeFloat.gt(:rand.uniform(), 0.5)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Random failure"]
    end
    "Success"
  end
  def main() do
    test_function_body()
    nil
  end
end
