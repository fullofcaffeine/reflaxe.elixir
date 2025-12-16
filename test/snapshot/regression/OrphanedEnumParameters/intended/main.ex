defmodule Main do
  defp test_basic_enum() do
    msg = (case {:created, "item"} do
      {:created, _content} -> nil
      {:updated, _id, _content} -> nil
      {:deleted, _id} -> nil
      {:empty} -> nil
    end)
  end
  defp test_multiple_parameters() do
    action = (case {:move, 10, 20, 30} do
      {:move, _x, _y, _z} -> nil
      {:rotate, _angle, _axis} -> nil
      {:scale, _factor} -> nil
    end)
  end
  defp test_empty_cases() do
    event = (case {:click, 100, 200} do
      {:click, _x, _y} -> nil
      {:hover, _x, _y} -> nil
      {:key_press, _key} -> nil
    end)
    nil
  end
  defp test_fall_through() do
    state = {:loading, 50}
    description = ""
    (case state do
      {:loading, _progress} -> nil
      {:processing, progress} -> description = "Progress: #{(fn -> Kernel.to_string(progress) end).()}%"
      {:complete, result} -> description = "Done: #{(fn -> result end).()}"
      {:error, msg} -> description = "Error: #{(fn -> msg end).()}"
    end)
    nil
  end
  defp test_nested_enums() do
    container = (case {:box, {:text, "Hello"}} do
      {:box, content} ->
        (case content do
          {:text, _str} -> nil
          {:number, _value} -> nil
          {:empty} -> nil
        end)
      {:list, _items} -> nil
      {:empty} -> nil
    end)
  end
  defp test_mixed_cases() do
    result = (case {:success, "Done", 42} do
      {:success, _message, _code} -> nil
      {:warning, _message} -> nil
      {:error, _message, _code} -> nil
      {:pending} -> nil
    end)
  end
end
