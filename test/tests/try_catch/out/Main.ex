defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Try-catch exception handling test case
 * Tests exception throwing, catching, and finally blocks
 
  """

  # Static functions
  @doc "Function basic_try_catch"
  @spec basic_try_catch() :: TAbstract(Void,[]).t()
  def basic_try_catch() do
    (
  try do
  (
  Log.trace("In try block", %{fileName: "Main.hx", lineNumber: 13, className: "Main", methodName: "basicTryCatch"})
  throw("Simple error")
  Log.trace("This won't execute", %{fileName: "Main.hx", lineNumber: 15, className: "Main", methodName: "basicTryCatch"})
)
rescue
  e ->
    Log.trace("Caught string: " + e, %{fileName: "Main.hx", lineNumber: 17, className: "Main", methodName: "basicTryCatch"})
end
  try do
  throw(Haxe.Exception.new("Exception object"))
rescue
  e ->
    Log.trace("Caught exception: " + e.get_message(), %{fileName: "Main.hx", lineNumber: 23, className: "Main", methodName: "basicTryCatch"})
end
)
  end

  @doc "Function multiple_catch"
  @spec multiple_catch() :: TAbstract(Void,[]).t()
  def multiple_catch() do
    (
  test_error = fn type -> try do
  case ((type)) do
  1 ->
    throw("String error")
  2 ->
    throw(42)
  3 ->
    throw(Haxe.Exception.new("Exception error"))
  4 ->
    throw(%{error: "Object error"})
  _ ->
    Log.trace("No error", %{fileName: "Main.hx", lineNumber: 36, className: "Main", methodName: "multipleCatch"})
end
rescue
  e ->
    Log.trace("Caught string: " + e, %{fileName: "Main.hx", lineNumber: 39, className: "Main", methodName: "multipleCatch"})
rescue
  e ->
    Log.trace("Caught int: " + e, %{fileName: "Main.hx", lineNumber: 41, className: "Main", methodName: "multipleCatch"})
rescue
  e ->
    Log.trace("Caught exception: " + e.get_message(), %{fileName: "Main.hx", lineNumber: 43, className: "Main", methodName: "multipleCatch"})
rescue
  e ->
    Log.trace("Caught dynamic: " + Std.string(e), %{fileName: "Main.hx", lineNumber: 45, className: "Main", methodName: "multipleCatch"})
end end
  test_error(1)
  test_error(2)
  test_error(3)
  test_error(4)
  test_error(0)
)
  end

  @doc "Function try_catch_finally"
  @spec try_catch_finally() :: TAbstract(Void,[]).t()
  def try_catch_finally() do
    (
  resource = "resource"
  try do
  (
  Log.trace("Acquiring resource", %{fileName: "Main.hx", lineNumber: 61, className: "Main", methodName: "tryCatchFinally"})
  throw("Error during operation")
)
rescue
  e ->
    Log.trace("Error: " + e, %{fileName: "Main.hx", lineNumber: 64, className: "Main", methodName: "tryCatchFinally"})
end
  try do
  Log.trace("Normal operation", %{fileName: "Main.hx", lineNumber: 74, className: "Main", methodName: "tryCatchFinally"})
rescue
  e ->
    nil
end
  Log.trace("After try-catch block", %{fileName: "Main.hx", lineNumber: 78, className: "Main", methodName: "tryCatchFinally"})
)
  end

  @doc "Function nested_try_catch"
  @spec nested_try_catch() :: TAbstract(Void,[]).t()
  def nested_try_catch() do
    try do
  (
  Log.trace("Outer try", %{fileName: "Main.hx", lineNumber: 84, className: "Main", methodName: "nestedTryCatch"})
  try do
  (
  Log.trace("Inner try", %{fileName: "Main.hx", lineNumber: 86, className: "Main", methodName: "nestedTryCatch"})
  throw("Inner error")
)
rescue
  e ->
    (
  Log.trace("Inner catch: " + e, %{fileName: "Main.hx", lineNumber: 89, className: "Main", methodName: "nestedTryCatch"})
  throw("Rethrow from inner")
)
end
)
rescue
  e ->
    Log.trace("Outer catch: " + e, %{fileName: "Main.hx", lineNumber: 93, className: "Main", methodName: "nestedTryCatch"})
end
  end

  @doc "Function custom_exception"
  @spec custom_exception() :: TAbstract(Void,[]).t()
  def custom_exception() do
    try do
  throw(CustomException.new("Custom error", 404))
rescue
  e ->
    Log.trace("Custom exception: " + e.get_message() + ", code: " + e.code, %{fileName: "Main.hx", lineNumber: 102, className: "Main", methodName: "customException"})
end
  end

  @doc "Function divide"
  @spec divide(TAbstract(Float,[]).t(), TAbstract(Float,[]).t()) :: TAbstract(Float,[]).t()
  def divide(arg0, arg1) do
    (
  if (b == 0), do: throw(Haxe.Exception.new("Division by zero")), else: nil
  a / b
)
  end

  @doc "Function test_division"
  @spec test_division() :: TAbstract(Void,[]).t()
  def test_division() do
    try do
  (
  result = Main.divide(10, 2)
  Log.trace("10 / 2 = " + result, %{fileName: "Main.hx", lineNumber: 117, className: "Main", methodName: "testDivision"})
  result = Main.divide(10, 0)
  Log.trace("This won't execute", %{fileName: "Main.hx", lineNumber: 120, className: "Main", methodName: "testDivision"})
)
rescue
  e ->
    Log.trace("Division error: " + e.get_message(), %{fileName: "Main.hx", lineNumber: 122, className: "Main", methodName: "testDivision"})
end
  end

  @doc "Function rethrow_example"
  @spec rethrow_example() :: TAbstract(Void,[]).t()
  def rethrow_example() do
    (
  inner_function = fn  -> throw(Haxe.Exception.new("Original error")) end
  middle_function = fn  -> try do
  inner_function()
rescue
  e ->
    (
  Log.trace("Middle caught: " + e.get_message(), %{fileName: "Main.hx", lineNumber: 136, className: "Main", methodName: "rethrowExample"})
  throw(e)
)
end end
  try do
  middle_function()
rescue
  e ->
    Log.trace("Outer caught rethrown: " + e.get_message(), %{fileName: "Main.hx", lineNumber: 144, className: "Main", methodName: "rethrowExample"})
end
)
  end

  @doc "Function stack_trace_example"
  @spec stack_trace_example() :: TAbstract(Void,[]).t()
  def stack_trace_example() do
    try do
  (
  level3 = fn  -> throw(Haxe.Exception.new("Deep error")) end
  level2 = fn  -> level3() end
  level1 = fn  -> level2() end
  level1()
)
rescue
  e ->
    (
  Log.trace("Error: " + e.get_message(), %{fileName: "Main.hx", lineNumber: 156, className: "Main", methodName: "stackTraceExample"})
  Log.trace("Stack would be printed here", %{fileName: "Main.hx", lineNumber: 158, className: "Main", methodName: "stackTraceExample"})
)
end
  end

  @doc "Function try_as_expression"
  @spec try_as_expression() :: TAbstract(Void,[]).t()
  def try_as_expression() do
    (
  temp_maybe_number = nil
  try do
  temp_maybe_number = Std.parseInt("123")
rescue
  e ->
    temp_maybe_number = 0
end
  value = temp_maybe_number
  Log.trace("Parsed value: " + value, %{fileName: "Main.hx", lineNumber: 169, className: "Main", methodName: "tryAsExpression"})
  temp_maybe_number1 = nil
  try do
  temp_maybe_number1 = Std.parseInt("not a number")
rescue
  e ->
    temp_maybe_number1 = -1
end
  value2 = temp_maybe_number1
  Log.trace("Failed parse value: " + value2, %{fileName: "Main.hx", lineNumber: 176, className: "Main", methodName: "tryAsExpression"})
)
  end

  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("=== Basic Try-Catch ===", %{fileName: "Main.hx", lineNumber: 180, className: "Main", methodName: "main"})
  Main.basicTryCatch()
  Log.trace("
=== Multiple Catch ===", %{fileName: "Main.hx", lineNumber: 183, className: "Main", methodName: "main"})
  Main.multipleCatch()
  Log.trace("
=== Try-Catch-Finally ===", %{fileName: "Main.hx", lineNumber: 186, className: "Main", methodName: "main"})
  Main.tryCatchFinally()
  Log.trace("
=== Nested Try-Catch ===", %{fileName: "Main.hx", lineNumber: 189, className: "Main", methodName: "main"})
  Main.nestedTryCatch()
  Log.trace("
=== Custom Exception ===", %{fileName: "Main.hx", lineNumber: 192, className: "Main", methodName: "main"})
  Main.customException()
  Log.trace("
=== Division Test ===", %{fileName: "Main.hx", lineNumber: 195, className: "Main", methodName: "main"})
  Main.testDivision()
  Log.trace("
=== Rethrow Example ===", %{fileName: "Main.hx", lineNumber: 198, className: "Main", methodName: "main"})
  Main.rethrowExample()
  Log.trace("
=== Stack Trace Example ===", %{fileName: "Main.hx", lineNumber: 201, className: "Main", methodName: "main"})
  Main.stackTraceExample()
  Log.trace("
=== Try as Expression ===", %{fileName: "Main.hx", lineNumber: 204, className: "Main", methodName: "main"})
  Main.tryAsExpression()
)
  end

end


defmodule CustomException do
  @moduledoc """
  CustomException module generated from Haxe
  """

end
