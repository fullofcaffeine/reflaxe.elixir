defmodule Main do
  def basic_try_catch() do
    try do
      Log.trace("In try block", %{:fileName => "Main.hx", :lineNumber => 13, :className => "Main", :methodName => "basicTryCatch"})
      throw("Simple error")
      Log.trace("This won't execute", %{:fileName => "Main.hx", :lineNumber => 15, :className => "Main", :methodName => "basicTryCatch"})
    rescue
      e ->
        Log.trace("Caught string: " + e, %{:fileName => "Main.hx", :lineNumber => 17, :className => "Main", :methodName => "basicTryCatch"})
    end
    try do
      throw(Exception.new("Exception object"))
    rescue
      e ->
        Log.trace("Caught exception: " + e.get_message(), %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "basicTryCatch"})
    end
  end
  def multiple_catch() do
    test_error = fn type -> try do
  case (type) do
    1 ->
      throw("String error")
    2 ->
      throw(42)
    3 ->
      throw(Exception.new("Exception error"))
    4 ->
      throw(%{:error => "Object error"})
    _ ->
      Log.trace("No error", %{:fileName => "Main.hx", :lineNumber => 36, :className => "Main", :methodName => "multipleCatch"})
  end
rescue
  e ->
    Log.trace("Caught string: " + e, %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "multipleCatch"})
  e ->
    Log.trace("Caught int: " + e, %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "multipleCatch"})
  e ->
    Log.trace("Caught exception: " + e.get_message(), %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "multipleCatch"})
  e ->
    Log.trace("Caught dynamic: " + Std.string(e), %{:fileName => "Main.hx", :lineNumber => 45, :className => "Main", :methodName => "multipleCatch"})
end end
    test_error.(1)
    test_error.(2)
    test_error.(3)
    test_error.(4)
    test_error.(0)
  end
  def try_catch_finally() do
    resource = "resource"
    try do
      Log.trace("Acquiring resource", %{:fileName => "Main.hx", :lineNumber => 61, :className => "Main", :methodName => "tryCatchFinally"})
      throw("Error during operation")
    rescue
      e ->
        Log.trace("Error: " + e, %{:fileName => "Main.hx", :lineNumber => 64, :className => "Main", :methodName => "tryCatchFinally"})
    end
    try do
      Log.trace("Normal operation", %{:fileName => "Main.hx", :lineNumber => 74, :className => "Main", :methodName => "tryCatchFinally"})
    rescue
      e ->
        nil
    end
    Log.trace("After try-catch block", %{:fileName => "Main.hx", :lineNumber => 78, :className => "Main", :methodName => "tryCatchFinally"})
  end
  def nested_try_catch() do
    try do
      Log.trace("Outer try", %{:fileName => "Main.hx", :lineNumber => 84, :className => "Main", :methodName => "nestedTryCatch"})
      try do
        Log.trace("Inner try", %{:fileName => "Main.hx", :lineNumber => 86, :className => "Main", :methodName => "nestedTryCatch"})
        throw("Inner error")
      rescue
        e ->
          Log.trace("Inner catch: " + e, %{:fileName => "Main.hx", :lineNumber => 89, :className => "Main", :methodName => "nestedTryCatch"})
          throw("Rethrow from inner")
      end
    rescue
      e ->
        Log.trace("Outer catch: " + e, %{:fileName => "Main.hx", :lineNumber => 93, :className => "Main", :methodName => "nestedTryCatch"})
    end
  end
  def custom_exception() do
    try do
      throw(CustomException.new("Custom error", 404))
    rescue
      e ->
        Log.trace("Custom exception: " + e.get_message() + ", code: " + e.code, %{:fileName => "Main.hx", :lineNumber => 102, :className => "Main", :methodName => "customException"})
    end
  end
  def divide(a, b) do
    if (b == 0) do
      throw(Exception.new("Division by zero"))
    end
    a / b
  end
  def test_division() do
    try do
      result = Main.divide(10, 2)
      Log.trace("10 / 2 = " + result, %{:fileName => "Main.hx", :lineNumber => 117, :className => "Main", :methodName => "testDivision"})
      result = Main.divide(10, 0)
      Log.trace("This won't execute", %{:fileName => "Main.hx", :lineNumber => 120, :className => "Main", :methodName => "testDivision"})
    rescue
      e ->
        Log.trace("Division error: " + e.get_message(), %{:fileName => "Main.hx", :lineNumber => 122, :className => "Main", :methodName => "testDivision"})
    end
  end
  def rethrow_example() do
    inner_function = fn -> throw(Exception.new("Original error")) end
    middle_function = fn -> try do
  inner_function.()
rescue
  e ->
    Log.trace("Middle caught: " + e.get_message(), %{:fileName => "Main.hx", :lineNumber => 136, :className => "Main", :methodName => "rethrowExample"})
    throw(e)
end end
    try do
      middle_function.()
    rescue
      e ->
        Log.trace("Outer caught rethrown: " + e.get_message(), %{:fileName => "Main.hx", :lineNumber => 144, :className => "Main", :methodName => "rethrowExample"})
    end
  end
  def stack_trace_example() do
    try do
      level_3 = fn -> throw(Exception.new("Deep error")) end
      level_2 = fn -> level_3.() end
      level_1 = fn -> level_2.() end
      level_1.()
    rescue
      e ->
        Log.trace("Error: " + e.get_message(), %{:fileName => "Main.hx", :lineNumber => 156, :className => "Main", :methodName => "stackTraceExample"})
        Log.trace("Stack would be printed here", %{:fileName => "Main.hx", :lineNumber => 158, :className => "Main", :methodName => "stackTraceExample"})
    end
  end
  def try_as_expression() do
    value = try do
  Std.parse_int("123")
rescue
  e ->
    0
end
    Log.trace("Parsed value: " + value, %{:fileName => "Main.hx", :lineNumber => 169, :className => "Main", :methodName => "tryAsExpression"})
    value_2 = try do
  Std.parse_int("not a number")
rescue
  e ->
    -1
end
    Log.trace("Failed parse value: " + value, %{:fileName => "Main.hx", :lineNumber => 176, :className => "Main", :methodName => "tryAsExpression"})
  end
  def main() do
    Log.trace("=== Basic Try-Catch ===", %{:fileName => "Main.hx", :lineNumber => 180, :className => "Main", :methodName => "main"})
    Main.basic_try_catch()
    Log.trace("\n=== Multiple Catch ===", %{:fileName => "Main.hx", :lineNumber => 183, :className => "Main", :methodName => "main"})
    Main.multiple_catch()
    Log.trace("\n=== Try-Catch-Finally ===", %{:fileName => "Main.hx", :lineNumber => 186, :className => "Main", :methodName => "main"})
    Main.try_catch_finally()
    Log.trace("\n=== Nested Try-Catch ===", %{:fileName => "Main.hx", :lineNumber => 189, :className => "Main", :methodName => "main"})
    Main.nested_try_catch()
    Log.trace("\n=== Custom Exception ===", %{:fileName => "Main.hx", :lineNumber => 192, :className => "Main", :methodName => "main"})
    Main.custom_exception()
    Log.trace("\n=== Division Test ===", %{:fileName => "Main.hx", :lineNumber => 195, :className => "Main", :methodName => "main"})
    Main.test_division()
    Log.trace("\n=== Rethrow Example ===", %{:fileName => "Main.hx", :lineNumber => 198, :className => "Main", :methodName => "main"})
    Main.rethrow_example()
    Log.trace("\n=== Stack Trace Example ===", %{:fileName => "Main.hx", :lineNumber => 201, :className => "Main", :methodName => "main"})
    Main.stack_trace_example()
    Log.trace("\n=== Try as Expression ===", %{:fileName => "Main.hx", :lineNumber => 204, :className => "Main", :methodName => "main"})
    Main.try_as_expression()
  end
end