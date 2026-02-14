defmodule AbstractionLab.ExponentialRetryPolicy do
  def should_retry(struct, attempt, _) do
    attempt < apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :max_attempts, [struct])
  end
  def next_delay_ms(_, attempt) do
    bounded_attempt = if (attempt < 0), do: 0, else: attempt
    _ = trunc(:math.pow(2, bounded_attempt) * 100)
  end
  def max_attempts(_) do
    5
  end
end
