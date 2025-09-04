defmodule Main do
  defp main() do
    test_basic_enum()
    test_multiple_parameters()
    test_empty_cases()
    test_fall_through()
    test_nested_enums()
    test_mixed_cases()
  end
  defp test_basic_enum() do
    msg = {:Created, "item"}
    case (msg.elem(0)) do
      0 ->
        g = msg.elem(1)
        content = g
        Log.trace("Created: " <> content, %{:fileName => "Main.hx", :lineNumber => 38, :className => "Main", :methodName => "testBasicEnum"})
      1 ->
        g = msg.elem(1)
        g1 = msg.elem(2)
        id = g
        content = g1
        Log.trace("Updated " <> id <> ": " <> content, %{:fileName => "Main.hx", :lineNumber => 40, :className => "Main", :methodName => "testBasicEnum"})
      2 ->
        g = msg.elem(1)
        id = g
        Log.trace("Deleted: " <> id, %{:fileName => "Main.hx", :lineNumber => 42, :className => "Main", :methodName => "testBasicEnum"})
      3 ->
        Log.trace("Empty message", %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "testBasicEnum"})
    end
  end
  defp test_multiple_parameters() do
    action = {:Move, 10, 20, 30}
    case (action.elem(0)) do
      0 ->
        g = action.elem(1)
        g1 = action.elem(2)
        g2 = action.elem(3)
        x = g
        y = g1
        z = g2
        Log.trace("Moving to (" <> x <> ", " <> y <> ", " <> z <> ")", %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "testMultipleParameters"})
      1 ->
        g = action.elem(1)
        g1 = action.elem(2)
        angle = g
        axis = g1
        Log.trace("Rotating " <> angle <> " degrees on " <> axis, %{:fileName => "Main.hx", :lineNumber => 55, :className => "Main", :methodName => "testMultipleParameters"})
      2 ->
        g = action.elem(1)
        factor = g
        Log.trace("Scaling by " <> factor, %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "testMultipleParameters"})
    end
  end
  defp test_empty_cases() do
    event = {:Click, 100, 200}
    case (event.elem(0)) do
      0 ->
        g = event.elem(1)
        g1 = event.elem(2)
        _x = g
        _y = g1
        nil
      1 ->
        g = event.elem(1)
        g1 = event.elem(2)
        _x = g
        _y = g1
        nil
      2 ->
        g = event.elem(1)
        _key = g
        nil
    end
    Log.trace("Empty cases handled", %{:fileName => "Main.hx", :lineNumber => 75, :className => "Main", :methodName => "testEmptyCases"})
  end
  defp test_fall_through() do
    state = {:Loading, 50}
    description = ""
    case (state.elem(0)) do
      0 ->
        g = state.elem(1)
        _progress = g
        nil
      1 ->
        g = state.elem(1)
        progress = g
        description = "Progress: " <> progress <> "%"
      2 ->
        g = state.elem(1)
        result = g
        description = "Done: " <> result
      3 ->
        g = state.elem(1)
        msg = g
        description = "Error: " <> msg
    end
    Log.trace(description, %{:fileName => "Main.hx", :lineNumber => 93, :className => "Main", :methodName => "testFallThrough"})
  end
  defp test_nested_enums() do
    container = {:Box, {:Text, "Hello"}}
    case (container.elem(0)) do
      0 ->
        g = container.elem(1)
        content = g
        case (content.elem(0)) do
          0 ->
            g = content.elem(1)
            str = g
            Log.trace("Box contains text: " <> str, %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "testNestedEnums"})
          1 ->
            g = content.elem(1)
            n = g
            Log.trace("Box contains number: " <> n, %{:fileName => "Main.hx", :lineNumber => 105, :className => "Main", :methodName => "testNestedEnums"})
          2 ->
            Log.trace("Box is empty", %{:fileName => "Main.hx", :lineNumber => 107, :className => "Main", :methodName => "testNestedEnums"})
        end
      1 ->
        g = container.elem(1)
        items = g
        Log.trace("List with " <> items.length <> " items", %{:fileName => "Main.hx", :lineNumber => 110, :className => "Main", :methodName => "testNestedEnums"})
      2 ->
        Log.trace("Container is empty", %{:fileName => "Main.hx", :lineNumber => 112, :className => "Main", :methodName => "testNestedEnums"})
    end
  end
  defp test_mixed_cases() do
    result = {:Success, "Done", 42}
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        g1 = result.elem(2)
        msg = g
        code = g1
        Log.trace("Success: " <> msg <> " (code: " <> code <> ")", %{:fileName => "Main.hx", :lineNumber => 121, :className => "Main", :methodName => "testMixedCases"})
      1 ->
        g = result.elem(1)
        _msg = g
        nil
      2 ->
        g = result.elem(1)
        g1 = result.elem(2)
        msg = g
        code = g1
        Log.trace("Error: " <> msg <> " (code: " <> code <> ")", %{:fileName => "Main.hx", :lineNumber => 125, :className => "Main", :methodName => "testMixedCases"})
      3 ->
        Log.trace("Still pending...", %{:fileName => "Main.hx", :lineNumber => 127, :className => "Main", :methodName => "testMixedCases"})
    end
  end
end