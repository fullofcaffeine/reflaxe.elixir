defmodule SourceMapValidationTest do
  @moduledoc """
    SourceMapValidationTest module generated from Haxe

     * Integration test to validate source map structure and content.
     * Tests that:
     * 1. Source maps are generated with correct v3 format
     * 2. VLQ encoding produces non-empty mappings
     * 3. Sources array correctly references Haxe files
     * 4. File paths are properly resolved
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Log.trace("=== Source Map Validation Test ===", %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 13, "className" => "SourceMapValidationTest", "methodName" => "main"})

    simple_var = "test"

    number = 42

    SourceMapValidationTest.test_function(simple_var, number)

    if ((number > 0)), do: Log.trace("Positive number", %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 24, "className" => "SourceMapValidationTest", "methodName" => "main"}), else: Log.trace("Non-positive number", %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 26, "className" => "SourceMapValidationTest", "methodName" => "main"})

    Log.trace("Loop iteration: " <> to_string(0), %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 31, "className" => "SourceMapValidationTest", "methodName" => "main"})

    Log.trace("Loop iteration: " <> to_string(1), %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 31, "className" => "SourceMapValidationTest", "methodName" => "main"})

    Log.trace("Loop iteration: " <> to_string(2), %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 31, "className" => "SourceMapValidationTest", "methodName" => "main"})

    Log.trace("Loop iteration: " <> to_string(3), %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 31, "className" => "SourceMapValidationTest", "methodName" => "main"})

    Log.trace("Loop iteration: " <> to_string(4), %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 31, "className" => "SourceMapValidationTest", "methodName" => "main"})

    array = [1, 2, 3, 4, 5]

    g_counter = 0

    (fn loop ->
      if ((g_counter < array.length)) do
            item = Enum.at(array, g_counter)
        g_counter + 1
        SourceMapValidationTest.process_item(item)
        loop.()
      end
    end).()

    _obj_name = "Test"

    _obj_value = 100

    _obj_nested_field = "nested value"

    instance = TestClass.new("example")

    instance.do_something()

    Log.trace("=== Test Complete ===", %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 53, "className" => "SourceMapValidationTest", "methodName" => "main"})
  end

  @doc "Generated from Haxe testFunction"
  def test_function(str, num) do
    Log.trace("Testing with: " <> str <> " and " <> to_string(num), %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 57, "className" => "SourceMapValidationTest", "methodName" => "testFunction"})
  end

  @doc "Generated from Haxe processItem"
  def process_item(item) do
    Log.trace("Processing item: " <> to_string(item), %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 61, "className" => "SourceMapValidationTest", "methodName" => "processItem"})
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
