defmodule Main do
  def main() do
    _msg1 = (case {:error, "failed"} do
      {:ok, _} -> "Success"
      {:error, g} -> "Error: #{g}"
    end)
    _msg2 = (case {:ok, 42} do
      {:ok, value} -> "Got: #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
      {:error, _} -> "Failed"
    end)
    _msg3 = (case {:some, "hello"} do
      {:some, value} -> "Value: #{value}"
      {:none} -> "Empty"
    end)
    _unwrapped = unwrap_or({:error, "oops"}, "default")
    nil
  end
  defp unwrap_or(result, default_value) do
    (case result do
      {:ok, value} -> value
      {:error, _error} -> default_value
    end)
  end
end
