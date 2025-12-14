defmodule Main do
  defp test_basic_enum() do
    msg = (case {:created, "item"} do
      {:created, __content} -> nil
      {:updated, id, __content} ->
        _content = id
        nil
      {:deleted, __id} -> nil
      {:empty} -> nil
    end)
  end
  defp test_multiple_parameters() do
    action = (case {:move, 10, 20, 30} do
      {:move, x, __y, __z} ->
        _y = x
        _z = x
        nil
      {:rotate, angle, __axis} ->
        _axis = angle
        nil
      {:scale, __factor} -> nil
    end)
  end
  defp test_empty_cases() do
    event = (case {:click, 100, 200} do
      {:click, x, __y} ->
        _y = x
      {:hover, x, __y} ->
        _y = x
      {:key_press, __key} -> nil
    end)
    nil
  end
  defp test_fall_through() do
    state = {:loading, 50}
    description = ""
    (case state do
      {:loading, __progress} -> nil
      {:processing, progress} ->
        to_string = progress
        description = "Progress: #{(fn -> Kernel.to_string(progress) end).()}%"
      {:complete, result} -> description = "Done: #{(fn -> result end).()}"
      {:error, reason} ->
        msg = reason
        description = "Error: #{(fn -> msg end).()}"
    end)
    nil
  end
  defp test_nested_enums() do
    container = (case {:box, {:text, "Hello"}} do
      {:box, content} ->
        (case content do
          {:text, __value} -> nil
          {:number, __value} -> nil
          {:empty} -> nil
        end)
      {:list, __items} -> nil
      {:empty} -> nil
    end)
  end
  defp test_mixed_cases() do
    result = (case {:success, "Done", 42} do
      {:success, message, __code} ->
        _msg = message
        _code = message
        nil
      {:warning, __message} -> nil
      {:error, reason, __code} ->
        _msg = reason
        _code = reason
        nil
      {:pending} -> nil
    end)
  end
end
