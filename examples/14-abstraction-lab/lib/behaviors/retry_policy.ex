defmodule AbstractionLab.RetryPolicy do
  def should_retry(_, _, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Callback must be implemented by behavior user"]
  end
  def next_delay_ms(_, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Callback must be implemented by behavior user"]
  end
  def max_attempts(_) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Optional callback can be implemented by behavior user"]
  end
end
