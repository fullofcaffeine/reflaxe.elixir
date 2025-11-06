defmodule Main do
  def basic_try_catch() do
    try do
      Log.trace("In try block", %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "basicTryCatch"})
      throw("Simple error")
      Log.trace("This won't execute", %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "basicTryCatch"})
    rescue
      e ->
        Log.trace("Caught string: " <> e, %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "basicTryCatch"})
    end
    try do
      throw(Exception.new("Exception object"))
    rescue
      e ->
        Log.trace("Caught exception: " <> e.get_message(), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "basicTryCatch"})
    end
  end
  def multiple_catch() do
    test_error = fn type ->
      try do
        (case type do
          1 -> throw("String error")
          2 -> throw(42)
          3 -> throw(Exception.new("Exception error"))
          4 -> throw(%{:error => "Object error"})
          _ ->
            Log.trace("No error", %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "multipleCatch"})
        end)
      rescue
        e ->
          Log.trace("Caught string: " <> e, %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "multipleCatch"})
        e ->
          Log.trace("Caught int: " <> Kernel.to_string(e), %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "multipleCatch"})
        e ->
          Log.trace("Caught exception: " <> e.get_message(), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "multipleCatch"})
        e ->
          Log.trace("Caught dynamic: " <> inspect(e), %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "multipleCatch"})
      end
    end
    _ = test_error.(1)
    _ = test_error.(2)
    _ = test_error.(3)
    _ = test_error.(4)
    _ = test_error.(0)
    _
  end
  def try_catch_finally() do
    _ = "resource"
    try do
      Log.trace("Acquiring resource", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "tryCatchFinally"})
      throw("Error during operation")
    rescue
      e ->
        Log.trace("Error: " <> e, %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "tryCatchFinally"})
    end
    try do
      Log.trace("Normal operation", %{:file_name => "Main.hx", :line_number => 74, :class_name => "Main", :method_name => "tryCatchFinally"})
    rescue
      e ->
        
    end
    _ = Log.trace("After try-catch block", %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "tryCatchFinally"})
    _
  end
  def nested_try_catch() do
    try do
      Log.trace("Outer try", %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "nestedTryCatch"})
      try do
        Log.trace("Inner try", %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "nestedTryCatch"})
        throw("Inner error")
      rescue
        e ->
          Log.trace("Inner catch: " <> e, %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "nestedTryCatch"})
          throw("Rethrow from inner")
      end
    rescue
      e ->
        Log.trace("Outer catch: " <> e, %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "nestedTryCatch"})
    end
  end
  def custom_exception() do
    try do
      throw(CustomException.new("Custom error", 404))
    rescue
      e ->
        Log.trace("Custom exception: " <> e.get_message() <> ", code: " <> Kernel.to_string(e.code), %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "customException"})
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
      result = divide(10, 2)
      Log.trace("10 / 2 = " <> Kernel.to_string(result), %{:file_name => "Main.hx", :line_number => 117, :class_name => "Main", :method_name => "testDivision"})
      result = divide(10, 0)
      Log.trace("This won't execute", %{:file_name => "Main.hx", :line_number => 120, :class_name => "Main", :method_name => "testDivision"})
    rescue
      e ->
        Log.trace("Division error: " <> e.get_message(), %{:file_name => "Main.hx", :line_number => 122, :class_name => "Main", :method_name => "testDivision"})
    end
  end
  def rethrow_example() do
    _ = fn -> throw(Exception.new("Original error")) end
    _ = fn ->
      try do
        inner_function.()
      rescue
        e ->
          Log.trace("Middle caught: " <> e.get_message(), %{:file_name => "Main.hx", :line_number => 136, :class_name => "Main", :method_name => "rethrowExample"})
          throw(e)
      end
    end
    try do
      middle_function.()
    rescue
      e ->
        Log.trace("Outer caught rethrown: " <> e.get_message(), %{:file_name => "Main.hx", :line_number => 144, :class_name => "Main", :method_name => "rethrowExample"})
    end
  end
  def stack_trace_example() do
    try do
      level3 = fn -> throw(Exception.new("Deep error")) end
      level2 = fn -> level3.() end
      level1 = fn -> level2.() end
      level1.()
    rescue
      e ->
        Log.trace("Error: " <> e.get_message(), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "stackTraceExample"})
        Log.trace("Stack would be printed here", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "stackTraceExample"})
    end
  end
  def try_as_expression() do
    _ = try do
      String.to_integer("123")
    rescue
      e ->
        0
    end
    _ = Log.trace("Parsed value: #{(fn -> value end).()}", %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "tryAsExpression"})
    _ = try do
      String.to_integer("not a number")
    rescue
      e ->
        -1
    end
    _ = Log.trace("Failed parse value: #{(fn -> value2 end).()}", %{:file_name => "Main.hx", :line_number => 176, :class_name => "Main", :method_name => "tryAsExpression"})
    _
  end
  def main() do
    _ = Log.trace("=== Basic Try-Catch ===", %{:file_name => "Main.hx", :line_number => 180, :class_name => "Main", :method_name => "main"})
    _ = basic_try_catch()
    _ = Log.trace("\n=== Multiple Catch ===", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "main"})
    _ = multiple_catch()
    _ = Log.trace("\n=== Try-Catch-Finally ===", %{:file_name => "Main.hx", :line_number => 186, :class_name => "Main", :method_name => "main"})
    _ = try_catch_finally()
    _ = Log.trace("\n=== Nested Try-Catch ===", %{:file_name => "Main.hx", :line_number => 189, :class_name => "Main", :method_name => "main"})
    _ = nested_try_catch()
    _ = Log.trace("\n=== Custom Exception ===", %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "main"})
    _ = custom_exception()
    _ = Log.trace("\n=== Division Test ===", %{:file_name => "Main.hx", :line_number => 195, :class_name => "Main", :method_name => "main"})
    _ = test_division()
    _ = Log.trace("\n=== Rethrow Example ===", %{:file_name => "Main.hx", :line_number => 198, :class_name => "Main", :method_name => "main"})
    _ = rethrow_example()
    _ = Log.trace("\n=== Stack Trace Example ===", %{:file_name => "Main.hx", :line_number => 201, :class_name => "Main", :method_name => "main"})
    _ = stack_trace_example()
    _ = Log.trace("\n=== Try as Expression ===", %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "main"})
    _ = try_as_expression()
    _
  end
end
