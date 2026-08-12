defmodule Main do
  def probe() do
    values = [1]
    _alias = values
    alias_ = []
    _ = values ++ [length(alias_)]
    length(alias_)
  end
  defp consume(value) do
    value
  end
  defp combine(first, second) do
    first * 10 + second
  end
  def ordinary_call_probe() do
    alias_ = []
    consume(length(alias_))
    length(alias_)
  end
  def block_local_probe() do
    consume(
      (fn ->
         local = 4
         _ = local + 1
       end).()
    )
  end
  def argument_order_probe() do
    second = [1]
    first = []
    reflaxe_call_value_0 = length(second)
    combine(reflaxe_call_value_0, length(first))
  end
  def main() do
    if (probe() != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected the call-argument assignment to remain visible after the call"]
    end
    if (ordinary_call_probe() != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected ordinary call arguments to use the same assignment scope rule"]
    end
    if (block_local_probe() != 5) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected a call-argument declaration to remain local to its block"]
    end
    if (argument_order_probe() != 10) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected call arguments to retain their left-to-right value order"]
    end
  end
end
