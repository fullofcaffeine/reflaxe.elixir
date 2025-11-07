defmodule Main do
  defp test_basic_enum() do
    msg = (case {:created, "item"} do
      {:created, content} ->
        Log.trace("Created: #{(fn -> content end).()}", %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testBasicEnum"})
      {:updated, id, content} -> _ = Log.trace("Updated #{(fn -> id end).()}: #{(fn -> content end).()}", %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testBasicEnum"})
      {:deleted, id} ->
        Log.trace("Deleted: #{(fn -> id end).()}", %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "testBasicEnum"})
      {:empty} ->
        Log.trace("Empty message", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "testBasicEnum"})
    end)
  end
  defp test_multiple_parameters() do
    action = (case {:move, 10, 20, 30} do
      {:move, x, y, z} ->
        Log.trace("Moving to (#{(fn -> x end).()}, #{(fn -> y end).()}, #{(fn -> z end).()})", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testMultipleParameters"})
      {:rotate, angle, axis} ->
        Log.trace("Rotating #{(fn -> angle end).()} degrees on #{(fn -> axis end).()}", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testMultipleParameters"})
      {:scale, factor} ->
        Log.trace("Scaling by #{(fn -> factor end).()}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testMultipleParameters"})
    end)
  end
  defp test_empty_cases() do
    event = (case {:click, 100, 200} do
      {:click, x, _y} ->
        y = x
      {:hover, x, _y} ->
        y = x
      {:key_press, g} -> key = g
    end)
    _ = Log.trace("Empty cases handled", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "testEmptyCases"})
  end
  defp test_fall_through() do
    state = {:loading, 50}
    description = ""
    (case state do
      {:loading, _progress} -> nil
      {:processing, _description} ->
        progress = _description
        description = "Progress: #{(fn -> progress end).()}%"
      {:complete, result} -> description = "Done: #{(fn -> result end).()}"
      {:error, msg} ->
        msg = value
        description = "Error: #{(fn -> msg end).()}"
    end)
    value = Log.trace(description, %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testFallThrough"})
    value
  end
  defp test_nested_enums() do
    container = (case {:box, {:text, "Hello"}} do
      {:box, content} ->
        n = content
        str = content
        (case content do
          {:text, str} ->
            Log.trace("Box contains text: #{(fn -> str end).()}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testNestedEnums"})
          {:number, n} ->
            Log.trace("Box contains number: #{(fn -> n end).()}", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testNestedEnums"})
          {:empty} ->
            Log.trace("Box is empty", %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testNestedEnums"})
        end)
      {:list, items} ->
        length = items
        Log.trace("List with #{(fn -> length(items) end).()} items", %{:file_name => "Main.hx", :line_number => 110, :class_name => "Main", :method_name => "testNestedEnums"})
      {:empty} ->
        Log.trace("Container is empty", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testNestedEnums"})
    end)
  end
  defp test_mixed_cases() do
    result = (case {:success, "Done", 42} do
      {:success, msg, code} -> _ = Log.trace("Success: #{(fn -> msg end).()} (code: #{(fn -> code end).()})", %{:file_name => "Main.hx", :line_number => 121, :class_name => "Main", :method_name => "testMixedCases"})
      {:warning, _message} -> nil
      {:error, _reason, code} -> _ = Log.trace("Error: #{(fn -> msg end).()} (code: #{(fn -> code end).()})", %{:file_name => "Main.hx", :line_number => 125, :class_name => "Main", :method_name => "testMixedCases"})
      {:pending} ->
        Log.trace("Still pending...", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testMixedCases"})
    end)
  end
end
