defmodule AbstractionLab.ImmediateRetryPolicy do
  def new() do
    %{:__reflaxe_class__ => AbstractionLab.ImmediateRetryPolicy}
  end

  def should_retry(struct, attempt, _last_error) do
    attempt <
      apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :max_attempts, [
        struct
      ])
  end

  def next_delay_ms(_struct, _attempt) do
    0
  end

  def max_attempts(_struct) do
    3
  end
end
