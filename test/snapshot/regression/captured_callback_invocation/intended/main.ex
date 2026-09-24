defmodule Main do
  defp order(a, b) do
    (a - b)
  end
  def main() do
    captured = [3, 1, 2]
    captured = Enum.sort(captured, fn a, b -> (&order/2).(a, b) < 0 end)
    if (Enum.join(captured, ",") != "1,2,3") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "captured comparator returned the wrong order"]
    end
    closure = [3, 1, 2]
    closure = Enum.sort(closure, fn a, b -> (fn a, b -> (b - a) end).(a, b) < 0 end)
    if (Enum.join(closure, ",") != "3,2,1") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "inline comparator returned the wrong order"]
    end
  end
end
