defmodule Main do
  def main() do
    result = {:error, "failed"}
    _msg1 = (case result do
      {:ok, _value} -> "Success"
      {:error, _g} -> "Error: #{_g}"
    end)
    result_value = {:ok, 42}
    _msg2 = (case result_value do
      {:ok, value} -> "Got: #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
      {:error, _error} -> "Failed"
    end)
    opt = {:some, "hello"}
    _msg3 = (case opt do
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
