defmodule AbstractionLab.ImmediateRetryPolicy do
  def should_retry(struct, attempt, _) do
    attempt < apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :max_attempts, [struct])
  end
  def next_delay_ms(_, _) do
    
  end
  def max_attempts(_) do
    3
  end
end
