defmodule Main do
  def main() do
    msg1 = (case {:error, "failed"} do
      {:ok, _} -> "Success"
      {:error, g} -> "Error: #{g}"
    end)
    msg2 = (case {:ok, 42} do
      {:ok, value} -> "Got: #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
      {:error, _} -> "Failed"
    end)
    msg3 = (case {:some, "hello"} do
      {:some, value} -> "Value: #{value}"
      {:none} -> "Empty"
    end)
    unwrapped = unwrap_or({:error, "oops"}, "default")
    if (msg1 != "Error: failed" or msg2 != "Got: 42" or msg3 != "Value: hello" or unwrapped != "default") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Enum branches must preserve their payload values"]
    end
    if (independent_alias({:ok, 42}) != 4243 or independent_alias({:error, "failed"}) != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Payload and alias must remain independent"]
    end
  end
  def independent_alias(result) do
    (case result do
      {:ok, value} ->
        g = value
        value = g
        value = value + 1
        g * 100 + value
      {:error, _} -> -1
    end)
  end
  defp unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        g = value
        value = g
        value
      {:error, _error} -> default_value
    end)
  end
end
