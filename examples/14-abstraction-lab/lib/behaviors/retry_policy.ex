defmodule AbstractionLab.RetryPolicy do
  def should_retry(_struct, _attempt, _last_error) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Callback must be implemented by behavior user"]
  end
  def next_delay_ms(_struct, _attempt) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Callback must be implemented by behavior user"]
  end
  def max_attempts(_struct) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Optional callback can be implemented by behavior user"]
  end
end
