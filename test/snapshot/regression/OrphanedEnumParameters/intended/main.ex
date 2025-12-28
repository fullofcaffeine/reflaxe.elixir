defmodule Main do
  def main() do
    _ = test_basic_enum()
    _ = test_multiple_parameters()
    _ = test_empty_cases()
    _ = test_fall_through()
    _ = test_nested_enums()
    _ = test_mixed_cases()
  end
  defp test_basic_enum() do
    _msg = (case {:created, "item"} do
      {:created, _content} -> nil
      {:updated, _id, _content} -> nil
      {:deleted, _id} -> nil
      {:empty} -> nil
    end)
  end
  defp test_multiple_parameters() do
    _action = (case {:move, 10, 20, 30} do
      {:move, _x, _y, _z} -> nil
      {:rotate, _angle, _axis} -> nil
      {:scale, _factor} -> nil
    end)
  end
  defp test_empty_cases() do
    _event = (case {:click, 100, 200} do
      {:click, _x, _y} -> nil
      {:hover, _x, _y} -> nil
      {:key_press, _key} -> nil
    end)
    nil
  end
  defp test_fall_through() do
    state = {:loading, 50}
    description = ""
    description = ((case state do
  {:loading, _progress} -> description
  {:processing, progress} ->
    description = "Progress: #{(fn -> Kernel.to_string(progress) end).()}%"
    description
  {:complete, result} ->
    description = "Done: #{(fn -> result end).()}"
    description
  {:error, msg} ->
    description = "Error: #{(fn -> msg end).()}"
    description
end))
    nil
  end
  defp test_nested_enums() do
    _container = (case {:box, {:text, "Hello"}} do
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
    _result = (case {:success, "Done", 42} do
      {:success, _message, _code} -> nil
      {:warning, _message} -> nil
      {:error, _message, _code} -> nil
      {:pending} -> nil
    end)
  end
end
