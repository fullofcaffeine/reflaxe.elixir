defmodule Main do
  def main() do
    test_basic_enum()
    test_multiple_parameters()
    test_empty_cases()
    if (test_fall_through({:loading, 50}) != "" or test_fall_through({:processing, 60}) != "Progress: 60%" or test_fall_through({:complete, "ready"}) != "Done: ready" or test_fall_through({:error, "offline"}) != "Error: offline") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Empty and non-empty enum branches must preserve their results"]
    end
    if (test_nested_enums({:box, {:text, "Hello"}}) != "Box contains text: Hello" or test_nested_enums({:box, {:number, 12}}) != "Box contains number: 12" or test_nested_enums({:box, {:empty}}) != "Box is empty" or test_nested_enums({:list, []}) != "List with 0 items" or test_nested_enums({:empty}) != "Container is empty") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested enum branches must preserve their payloads"]
    end
    test_mixed_cases()
  end
  defp test_basic_enum() do
    (case {:created, "item"} do
      {:created, _content} -> nil
      {:updated, _id, _content} -> nil
      {:deleted, _id} -> nil
      {:empty} -> nil
    end)
  end
  defp test_multiple_parameters() do
    (case {:move, 10, 20, 30} do
      {:move, _x, _y, _z} -> nil
      {:rotate, _angle, _axis} -> nil
      {:scale, _factor} -> nil
    end)
  end
  defp test_empty_cases() do
    (case {:click, 100, 200} do
      {:click, _x, _y} -> nil
      {:hover, _x, _y} -> nil
      {:key_press, _key} -> nil
    end)
    nil
  end
  defp test_fall_through(state) do
    description = ""
    description = (case state do
      {:loading, _progress} -> description
      {:processing, progress} ->
        description = "Progress: #{Reflaxe.Elixir.HaxeFloat.to_string(progress)}%"
        description
      {:complete, result} ->
        description = "Done: #{result}"
        description
      {:error, msg} ->
        description = "Error: #{msg}"
        description
    end)
    description
  end
  defp test_nested_enums(container) do
    (case container do
      {:box, content} ->
        (case content do
          {:text, str} -> "Box contains text: #{str}"
          {:number, n} -> "Box contains number: #{Reflaxe.Elixir.HaxeFloat.to_string(n)}"
          {:empty} -> "Box is empty"
        end)
      {:list, items} -> "List with #{Reflaxe.Elixir.HaxeFloat.to_string(length(items))} items"
      {:empty} -> "Container is empty"
    end)
  end
  defp test_mixed_cases() do
    (case {:success, "Done", 42} do
      {:success, message, _code} ->
        _msg = message
        nil
      {:warning, _message} -> nil
      {:error, message, _code} ->
        _msg = message
        nil
      {:pending} -> nil
    end)
  end
end
