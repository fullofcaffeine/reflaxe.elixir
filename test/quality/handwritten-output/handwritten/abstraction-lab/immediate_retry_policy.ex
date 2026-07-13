defmodule HandwrittenCorpus.AbstractionLab.ImmediateRetryPolicy do
  @max_attempts 3

  def should_retry(attempt, _last_error), do: attempt < @max_attempts
  def next_delay_ms(_attempt), do: 0
  def max_attempts, do: @max_attempts
end
