defmodule Main do
  defp test_function_body() do
    fn_ = fn x ->
      doubled = x * 2
      tripled = x * 3
      doubled + tripled
    end
    _ = fn_.(5)
  end
  defp perform_risky_operation() do
    if (:rand.uniform() > 0.5) do
      throw("Random failure")
    end
    "Success"
  end
  def main() do
    _ = test_function_body()
    nil
  end
end
