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
        Log.trace("Created: #{content}", %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testBasicEnum"})
      {:updated, id, content} ->
        Log.trace("Updated #{id}: #{content}", %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testBasicEnum"})
      {:deleted, id} ->
        Log.trace("Deleted: #{id}", %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "testBasicEnum"})
      :empty ->
        Log.trace("Empty message", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "testBasicEnum"})
    end
  end
  defp test_multiple_parameters() do
    action = {:move, 10, 20, 30}
    case (action) do
      {:move, x, y, z} ->
        Log.trace("Moving to (#{x}, #{y}, #{z})", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testMultipleParameters"})
      {:rotate, angle, axis} ->
        Log.trace("Rotating #{angle} degrees on #{axis}", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testMultipleParameters"})
      {:scale, factor} ->
        Log.trace("Scaling by #{factor}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testMultipleParameters"})
    end
  end
  defp test_empty_cases() do
    event = {:click, 100, 200}
    case (event) do
      {:click, _x, _y} ->
        nil
      {:hover, _x, _y} ->
        nil
      {:key_press, _key} ->
        nil
    end
    Log.trace("Empty cases handled", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "testEmptyCases"})
  end
  defp test_fall_through() do
    state = {:loading, 50}
    description = ""
    case (state) do
      {:loading, _progress} ->
        nil
      {:processing, description} ->
        description = "Progress: #{progress}%"
      {:complete, description} ->
        description = "Done: #{result}"
      {:error, description} ->
        description = "Error: #{msg}"
    end
    Log.trace(description, %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testFallThrough"})
  end
  defp test_nested_enums() do
    container = {:box, {:text, "Hello"}}
    case (container) do
      {:box, content} ->
        case (content) do
          {:text, str} ->
            Log.trace("Box contains text: #{str}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testNestedEnums"})
          {:number, n} ->
            Log.trace("Box contains number: #{n}", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testNestedEnums"})
          :empty ->
            Log.trace("Box is empty", %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testNestedEnums"})
        end
      {:list, items} ->
        Log.trace("List with #{length(items)} items", %{:file_name => "Main.hx", :line_number => 110, :class_name => "Main", :method_name => "testNestedEnums"})
      :empty ->
        Log.trace("Container is empty", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testNestedEnums"})
    end
  end
  defp test_mixed_cases() do
    result = {:success, "Done", 42}
    case (result) do
      {:success, msg, code} ->
        Log.trace("Success: #{msg} (code: #{code})", %{:file_name => "Main.hx", :line_number => 121, :class_name => "Main", :method_name => "testMixedCases"})
      {:warning, _message} ->
        nil
      {:error, msg, code} ->
        Log.trace("Error: #{msg} (code: #{code})", %{:file_name => "Main.hx", :line_number => 125, :class_name => "Main", :method_name => "testMixedCases"})
      :pending ->
        Log.trace("Still pending...", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testMixedCases"})
    end
  end
end