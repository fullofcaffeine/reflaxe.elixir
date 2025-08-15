defmodule SourceMapValidationTest do
  use Bitwise
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
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== Source Map Validation Test ===", %{fileName: "SourceMapValidationTest.hx", lineNumber: 13, className: "SourceMapValidationTest", methodName: "main"})
    simple_var = "test"
    number = 42
    SourceMapValidationTest.testFunction(simple_var, number)
    if (number > 0), do: Log.trace("Positive number", %{fileName: "SourceMapValidationTest.hx", lineNumber: 24, className: "SourceMapValidationTest", methodName: "main"}), else: Log.trace("Non-positive number", %{fileName: "SourceMapValidationTest.hx", lineNumber: 26, className: "SourceMapValidationTest", methodName: "main"})
    Log.trace("Loop iteration: " <> Integer.to_string(0), %{fileName: "SourceMapValidationTest.hx", lineNumber: 31, className: "SourceMapValidationTest", methodName: "main"})
    Log.trace("Loop iteration: " <> Integer.to_string(1), %{fileName: "SourceMapValidationTest.hx", lineNumber: 31, className: "SourceMapValidationTest", methodName: "main"})
    Log.trace("Loop iteration: " <> Integer.to_string(2), %{fileName: "SourceMapValidationTest.hx", lineNumber: 31, className: "SourceMapValidationTest", methodName: "main"})
    Log.trace("Loop iteration: " <> Integer.to_string(3), %{fileName: "SourceMapValidationTest.hx", lineNumber: 31, className: "SourceMapValidationTest", methodName: "main"})
    Log.trace("Loop iteration: " <> Integer.to_string(4), %{fileName: "SourceMapValidationTest.hx", lineNumber: 31, className: "SourceMapValidationTest", methodName: "main"})
    array = [1, 2, 3, 4, 5]
    _g = 0
    Enum.map(array, fn item -> item end)
    "Test"
    100
    "nested value"
    instance = TestClass.new("example")
    instance.doSomething()
    Log.trace("=== Test Complete ===", %{fileName: "SourceMapValidationTest.hx", lineNumber: 53, className: "SourceMapValidationTest", methodName: "main"})
  end

  @doc "Function test_function"
  @spec test_function(String.t(), integer()) :: nil
  def test_function(str, num) do
    Log.trace("Testing with: " <> str <> " and " <> Integer.to_string(num), %{fileName: "SourceMapValidationTest.hx", lineNumber: 57, className: "SourceMapValidationTest", methodName: "testFunction"})
  end

  @doc "Function process_item"
  @spec process_item(integer()) :: nil
  def process_item(item) do
    Log.trace("Processing item: " <> Integer.to_string(item), %{fileName: "SourceMapValidationTest.hx", lineNumber: 61, className: "SourceMapValidationTest", methodName: "processItem"})
  end

end


defmodule TestClass do
  use Bitwise
  @moduledoc """
  TestClass module generated from Haxe
  """

  # Instance functions
  @doc "Function do_something"
  @spec do_something() :: nil
  def do_something() do
    Log.trace("TestClass doing something with: " <> __MODULE__.name, %{fileName: "SourceMapValidationTest.hx", lineNumber: 73, className: "TestClass", methodName: "doSomething"})
  end

end
