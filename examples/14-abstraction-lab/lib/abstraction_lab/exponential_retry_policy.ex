defmodule AbstractionLab.ExponentialRetryPolicy do
  def new() do
    %{:__reflaxe_class__ => AbstractionLab.ExponentialRetryPolicy}
  end
  def should_retry(struct, attempt, _last_error) do
    attempt < apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :max_attempts, [struct])
  end
  def next_delay_ms(_struct, attempt) do
    bounded_attempt = if (attempt < 0), do: 0, else: attempt
    trunc(Reflaxe.Elixir.HaxeFloat.mul(Reflaxe.Elixir.HaxeFloat.pow(2, bounded_attempt), 100))
  end
  def max_attempts(_struct) do
    5
  end
end
