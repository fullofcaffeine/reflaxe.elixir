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
    case (elem(msg, 0)) do
      0 ->
        g = elem(msg, 1)
        content = g
        Log.trace("Created: " <> content, %{:fileName => "Main.hx", :lineNumber => 38, :className => "Main", :methodName => "testBasicEnum"})
      1 ->
        g = elem(msg, 1)
        g1 = elem(msg, 2)
        id = g
        content = g1
        Log.trace("Updated " <> id <> ": " <> content, %{:fileName => "Main.hx", :lineNumber => 40, :className => "Main", :methodName => "testBasicEnum"})
      2 ->
        g = elem(msg, 1)
        id = g
        Log.trace("Deleted: " <> id, %{:fileName => "Main.hx", :lineNumber => 42, :className => "Main", :methodName => "testBasicEnum"})
      3 ->
        Log.trace("Empty message", %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "testBasicEnum"})
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
        Log.trace("Moving to (" <> x <> ", " <> y <> ", " <> z <> ")", %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "testMultipleParameters"})
      1 ->
        g = elem(action, 1)
        g1 = elem(action, 2)
        angle = g
        axis = g1
        Log.trace("Rotating " <> angle <> " degrees on " <> axis, %{:fileName => "Main.hx", :lineNumber => 55, :className => "Main", :methodName => "testMultipleParameters"})
      2 ->
        g = elem(action, 1)
        factor = g
        Log.trace("Scaling by " <> factor, %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "testMultipleParameters"})
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
    Log.trace("Empty cases handled", %{:fileName => "Main.hx", :lineNumber => 75, :className => "Main", :methodName => "testEmptyCases"})
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
        description = "Progress: " <> progress <> "%"
      2 ->
        g = elem(state, 1)
        result = g
        description = "Done: " <> result
      3 ->
        g = elem(state, 1)
        msg = g
        description = "Error: " <> msg
    end
    Log.trace(description, %{:fileName => "Main.hx", :lineNumber => 93, :className => "Main", :methodName => "testFallThrough"})
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
            Log.trace("Box contains text: " <> str, %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "testNestedEnums"})
          1 ->
            g = elem(content, 1)
            n = g
            Log.trace("Box contains number: " <> n, %{:fileName => "Main.hx", :lineNumber => 105, :className => "Main", :methodName => "testNestedEnums"})
          2 ->
            Log.trace("Box is empty", %{:fileName => "Main.hx", :lineNumber => 107, :className => "Main", :methodName => "testNestedEnums"})
        end
      1 ->
        g = elem(container, 1)
        items = g
        Log.trace("List with " <> items.length <> " items", %{:fileName => "Main.hx", :lineNumber => 110, :className => "Main", :methodName => "testNestedEnums"})
      2 ->
        Log.trace("Container is empty", %{:fileName => "Main.hx", :lineNumber => 112, :className => "Main", :methodName => "testNestedEnums"})
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
        Log.trace("Success: " <> msg <> " (code: " <> code <> ")", %{:fileName => "Main.hx", :lineNumber => 121, :className => "Main", :methodName => "testMixedCases"})
      1 ->
        g = elem(result, 1)
        _msg = g
        nil
      2 ->
        g = elem(result, 1)
        g1 = elem(result, 2)
        msg = g
        code = g1
        Log.trace("Error: " <> msg <> " (code: " <> code <> ")", %{:fileName => "Main.hx", :lineNumber => 125, :className => "Main", :methodName => "testMixedCases"})
      3 ->
        Log.trace("Still pending...", %{:fileName => "Main.hx", :lineNumber => 127, :className => "Main", :methodName => "testMixedCases"})
    end
  end
end