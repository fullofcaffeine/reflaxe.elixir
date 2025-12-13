defmodule Main do
  def main() do
    test_result = {:ok, "success"}
    opt = to_option(test_result)
    unwrapped = unwrap_or(test_result, "default")
    nil
  end
  def to_option(result) do
    (case result do
      {:ok, value} ->
        _some = value
        {:some, value}
      {:error, __reason} -> {:none}
    end)
  end
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = value
        default_value
      {:error, reason} -> reason
    end)
  end
end
