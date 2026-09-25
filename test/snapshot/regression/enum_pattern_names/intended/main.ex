defmodule Main do
  def main() do
    assert_text(describe_status({:loading}), "Loading...")
    assert_text(describe_status({:success, "Hello World"}), "Got data: Hello World")
    assert_text(describe_status({:failure, "Network", 500}), "Error 500: Network")
    assert_text(describe_nested({:ok, {:loading}}), "Still loading")
    assert_text(describe_nested({:ok, {:success, "Nested"}}), "Nested success: Nested")
    assert_text(describe_nested({:ok, {:failure, "Offline", 503}}), "Nested failure 503: Offline")
    assert_text(describe_nested({:error, "Missing"}), "Top level error: Missing")
    assert_text(describe_mixed({:success, "ignored"}), "Success (data ignored)")
    assert_text(describe_mixed({:failure, "Network error", 500}), "Error occurred: Network error")
    assert_text(describe_mixed({:loading}), "Loading")
  end
  defp assert_text(actual, expected) do
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected " <> expected <> ", got " <> actual]
    end
  end
  defp describe_status(status) do
    (case status do
      {:loading} -> "Loading..."
      {:success, data} -> "Got data: #{data}"
      {:failure, error, code} -> "Error #{Reflaxe.Elixir.HaxeFloat.to_string(code)}: #{error}"
    end)
  end
  defp describe_nested(nested) do
    (case nested do
      {:ok, status} ->
        (case status do
          {:loading} -> "Still loading"
          {:success, data} -> "Nested success: #{data}"
          {:failure, error, code} -> "Nested failure #{Reflaxe.Elixir.HaxeFloat.to_string(code)}: #{error}"
        end)
      {:error, message} -> "Top level error: #{message}"
    end)
  end
  defp describe_mixed(mixed) do
    (case mixed do
      {:loading} -> "Loading"
      {:success, _} -> "Success (data ignored)"
      {:failure, error, _} -> "Error occurred: #{error}"
    end)
  end
end
