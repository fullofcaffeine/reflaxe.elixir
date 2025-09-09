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
    msg = {:Created, "item"}
    case (elem(msg, 0)) do
      0 ->
        g = elem(msg, 1)
        content = g
        Log.trace("Created: " <> content, %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testBasicEnum"})
      1 ->
        g = elem(msg, 1)
        g1 = elem(msg, 2)
        id = g
        content = g1
        Log.trace("Updated " <> Kernel.to_string(id) <> ": " <> content, %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testBasicEnum"})
      2 ->
        g = elem(msg, 1)
        id = g
        Log.trace("Deleted: " <> Kernel.to_string(id), %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "testBasicEnum"})
      3 ->
        Log.trace("Empty message", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "testBasicEnum"})
    end
  end
  defp test_multiple_parameters() do
    action = {:Move, 10, 20, 30}
    case (elem(action, 0)) do
      0 ->
        g = elem(action, 1)
        g1 = elem(action, 2)
        g2 = elem(action, 3)
        x = g
        y = g1
        z = g2
        Log.trace("Moving to (" <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> ", " <> Kernel.to_string(z) <> ")", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testMultipleParameters"})
      1 ->
        g = elem(action, 1)
        g1 = elem(action, 2)
        angle = g
        axis = g1
        Log.trace("Rotating " <> Kernel.to_string(angle) <> " degrees on " <> axis, %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testMultipleParameters"})
      2 ->
        g = elem(action, 1)
        factor = g
        Log.trace("Scaling by " <> Kernel.to_string(factor), %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testMultipleParameters"})
    end
  end
  defp test_empty_cases() do
    event = {:Click, 100, 200}
    case (elem(event, 0)) do
      0 ->
        g = elem(event, 1)
        g1 = elem(event, 2)
        _x = g
        _y = g1
        nil
      1 ->
        g = elem(event, 1)
        g1 = elem(event, 2)
        _x = g
        _y = g1
        nil
      2 ->
        g = elem(event, 1)
        _key = g
        nil
    end
    Log.trace("Empty cases handled", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "testEmptyCases"})
  end
  defp test_fall_through() do
    state = {:Loading, 50}
    description = ""
    case (elem(state, 0)) do
      0 ->
        g = elem(state, 1)
        _progress = g
        nil
      1 ->
        g = elem(state, 1)
        progress = g
        description = "Progress: " <> Kernel.to_string(progress) <> "%"
      2 ->
        g = elem(state, 1)
        result = g
        description = "Done: " <> result
      3 ->
        g = elem(state, 1)
        msg = g
        description = "Error: " <> msg
    end
    Log.trace(description, %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testFallThrough"})
  end
  defp test_nested_enums() do
    container = {:Box, {:Text, "Hello"}}
    case (elem(container, 0)) do
      0 ->
        g = elem(container, 1)
        content = g
        case (elem(content, 0)) do
          0 ->
            g = elem(content, 1)
            str = g
            Log.trace("Box contains text: " <> str, %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testNestedEnums"})
          1 ->
            g = elem(content, 1)
            n = g
            Log.trace("Box contains number: " <> Kernel.to_string(n), %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testNestedEnums"})
          2 ->
            Log.trace("Box is empty", %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testNestedEnums"})
        end
      1 ->
        g = elem(container, 1)
        items = g
        Log.trace("List with " <> Kernel.to_string(length(items)) <> " items", %{:file_name => "Main.hx", :line_number => 110, :class_name => "Main", :method_name => "testNestedEnums"})
      2 ->
        Log.trace("Container is empty", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testNestedEnums"})
    end
  end
  defp test_mixed_cases() do
    result = {:Success, "Done", 42}
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        g1 = elem(result, 2)
        msg = g
        code = g1
        Log.trace("Success: " <> msg <> " (code: " <> Kernel.to_string(code) <> ")", %{:file_name => "Main.hx", :line_number => 121, :class_name => "Main", :method_name => "testMixedCases"})
      1 ->
        g = elem(result, 1)
        _msg = g
        nil
      2 ->
        g = elem(result, 1)
        g1 = elem(result, 2)
        msg = g
        code = g1
        Log.trace("Error: " <> msg <> " (code: " <> Kernel.to_string(code) <> ")", %{:file_name => "Main.hx", :line_number => 125, :class_name => "Main", :method_name => "testMixedCases"})
      3 ->
        Log.trace("Still pending...", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testMixedCases"})
    end
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()