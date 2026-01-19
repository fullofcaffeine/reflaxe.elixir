defmodule Main do
  def main() do
    _ = test_ignored_parameter()
    _ = test_used_parameter()
    nil
  end
  defp test_ignored_parameter() do
    result = get_result()
    switch_result_1 = (case result do
      {:ok, _value} -> "Success"
      {:error, _message} -> "Failed"
    end)
    switch_result_1
  end
  defp test_used_parameter() do
    result = get_result()
    switch_result_2 = (case result do
      {:ok, value} -> "Got: #{value}"
      {:error, msg} -> "Error: #{msg}"
    end)
    switch_result_2
  end
  defp get_result() do
    {:ok, "test value"}
  end
end
