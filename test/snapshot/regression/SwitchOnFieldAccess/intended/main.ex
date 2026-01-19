defmodule Main do
  def main() do
    msg = %{:type => "test", :value => 42}
    _ = parse_message1(msg)
    _ = parse_message2(msg)
    nil
  end
  defp parse_message1(msg) do
    (case Map.get(msg, :type) do
      "other" -> {:some, "found other"}
      "test" -> {:some, "found test"}
      _ -> {:none}
    end)
  end
  defp parse_message2(msg) do
    if (Kernel.is_nil(msg)) do
      {:none}
    else
      (case Map.get(msg, :type) do
        "other" -> {:some, "found other"}
        "test" -> {:some, "found test"}
        _ -> {:none}
      end)
    end
  end
end
