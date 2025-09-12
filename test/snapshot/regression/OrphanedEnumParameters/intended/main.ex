defmodule Main do
  def main() do
    test_basic_enum()
    test_multiple_parameters()
    test_empty_cases()
    test_fall_through()
    test_nested_enums()
    test_mixed_cases()
  end
  defp test_basic_enum() do
    msg = {:created, "item"}
    case (msg) do
      {:created, content} ->
        g = elem(msg, 1)
        content = g
        Log.trace("Created: " <> content, %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testBasicEnum"})
      {:updated, id, content} ->
        g = elem(msg, 1)
        g1 = elem(msg, 2)
        id = g
        content = g1
        Log.trace("Updated " <> Kernel.to_string(id) <> ": " <> content, %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testBasicEnum"})
      {:deleted, id} ->
        g = elem(msg, 1)
        id = g
        Log.trace("Deleted: " <> Kernel.to_string(id), %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "testBasicEnum"})
      {:empty} ->
        Log.trace("Empty message", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "testBasicEnum"})
    end
  end
  defp test_multiple_parameters() do
    action = {:move, 10, 20, 30}
    case (action) do
      {:move, x, y, z} ->
        g = elem(action, 1)
        g1 = elem(action, 2)
        g2 = elem(action, 3)
        x = g
        y = g1
        z = g2
        Log.trace("Moving to (" <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> ", " <> Kernel.to_string(z) <> ")", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testMultipleParameters"})
      {:rotate, angle, axis} ->
        g = elem(action, 1)
        g1 = elem(action, 2)
        angle = g
        axis = g1
        Log.trace("Rotating " <> Kernel.to_string(angle) <> " degrees on " <> axis, %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testMultipleParameters"})
      {:scale, factor} ->
        g = elem(action, 1)
        factor = g
        Log.trace("Scaling by " <> Kernel.to_string(factor), %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testMultipleParameters"})
    end
  end
  defp test_empty_cases() do
    event = {:click, 100, 200}
    case (event) do
      {:click, x, y} ->
        g = elem(event, 1)
        g1 = elem(event, 2)
        x = g
        y = g1
        nil
      {:hover, x, y} ->
        g = elem(event, 1)
        g1 = elem(event, 2)
        x = g
        y = g1
        nil
      {:key_press, key} ->
        g = elem(event, 1)
        _key = g
        nil
    end
    Log.trace("Empty cases handled", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "testEmptyCases"})
  end
  defp test_fall_through() do
    state = {:loading, 50}
    description = ""
    case (state) do
      {:loading, progress} ->
        g = elem(state, 1)
        _progress = g
        nil
      {:processing, progress} ->
        g = elem(state, 1)
        progress = g
        description = "Progress: " <> Kernel.to_string(progress) <> "%"
      {:complete, result} ->
        g = elem(state, 1)
        result = g
        description = "Done: " <> result
      {:error, message} ->
        g = elem(state, 1)
        msg = g
        description = "Error: " <> msg
    end
    Log.trace(description, %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testFallThrough"})
  end
  defp test_nested_enums() do
    container = {:box, {:text, "Hello"}}
    case (container) do
      {:box, content} ->
        g = elem(container, 1)
        content = g
        case (content) do
          {:text, value} ->
            g = elem(content, 1)
            str = g
            Log.trace("Box contains text: " <> str, %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testNestedEnums"})
          {:number, value} ->
            g = elem(content, 1)
            n = g
            Log.trace("Box contains number: " <> Kernel.to_string(n), %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testNestedEnums"})
          {:empty} ->
            Log.trace("Box is empty", %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testNestedEnums"})
        end
      {:list, items} ->
        g = elem(container, 1)
        items = g
        Log.trace("List with " <> Kernel.to_string(length(items)) <> " items", %{:file_name => "Main.hx", :line_number => 110, :class_name => "Main", :method_name => "testNestedEnums"})
      {:empty} ->
        Log.trace("Container is empty", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testNestedEnums"})
    end
  end
  defp test_mixed_cases() do
    result = {:success, "Done", 42}
    case (result) do
      {:success, message, code} ->
        g = elem(result, 1)
        g1 = elem(result, 2)
        msg = g
        code = g1
        Log.trace("Success: " <> msg <> " (code: " <> Kernel.to_string(code) <> ")", %{:file_name => "Main.hx", :line_number => 121, :class_name => "Main", :method_name => "testMixedCases"})
      {:warning, message} ->
        g = elem(result, 1)
        _msg = g
        nil
      {:error, message, code} ->
        g = elem(result, 1)
        g1 = elem(result, 2)
        msg = g
        code = g1
        Log.trace("Error: " <> msg <> " (code: " <> Kernel.to_string(code) <> ")", %{:file_name => "Main.hx", :line_number => 125, :class_name => "Main", :method_name => "testMixedCases"})
      {:pending} ->
        Log.trace("Still pending...", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testMixedCases"})
    end
  end
end