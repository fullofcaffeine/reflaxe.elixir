defmodule Main do
  def main() do
    msg = %{type: "test", value: 42}
    _ = parse_message1(msg)
    _ = parse_message2(msg)
    nil
  end
  defp parse_message1(msg) do
    (case (case msg do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "type") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :type)
        end)
    end) do
      "other" -> {:some, "found other"}
      "test" -> {:some, "found test"}
      _ -> {:none}
    end)
  end
  defp parse_message2(msg) do
    if (Reflaxe.Elixir.HaxeFloat.eq(msg, nil)) do
      {:none}
    else
      (case (case msg do
        dyn_obj ->
          (case Map.fetch(dyn_obj, "type") do
            {:ok, dyn_value} -> dyn_value
            _ ->
              Map.get(dyn_obj, :type)
          end)
      end) do
        "other" -> {:some, "found other"}
        "test" -> {:some, "found test"}
        _ -> {:none}
      end)
    end
  end
end
