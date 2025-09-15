defmodule Main do
  def basic_try_catch() do
    try do
      Log.trace("In try block", %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "basicTryCatch"})
      throw("Simple error")
      Log.trace("This won't execute", %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "basicTryCatch"})
    catch
      error ->
        Log.trace("Caught string: #{error}", %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "basicTryCatch"})
    end

    try do
      raise "Exception object"
    rescue
      e in RuntimeError ->
        Log.trace("Caught exception: #{e.message}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "basicTryCatch"})
    end
  end

  def multiple_catch() do
    test_error = fn type ->
      try do
        case type do
          1 ->
            throw("String error")
          2 ->
            throw(42)
          3 ->
            raise "Exception error"
          4 ->
            throw(%{error: "Object error"})
          _ ->
            Log.trace("No error", %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "multipleCatch"})
        end
      catch
        error when is_binary(error) ->
          Log.trace("Caught string: #{error}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "multipleCatch"})
        error when is_integer(error) ->
          Log.trace("Caught int: #{error}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "multipleCatch"})
        error ->
          Log.trace("Caught dynamic: #{inspect(error)}", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "multipleCatch"})
      rescue
        e in RuntimeError ->
          Log.trace("Caught exception: #{e.message}", %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "multipleCatch"})
      end
    end

    test_error.(1)
    test_error.(2)
    test_error.(3)
    test_error.(4)
    test_error.(0)
  end

  def try_catch_finally() do
    _resource = "resource"
    try do
      Log.trace("Acquiring resource", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "tryCatchFinally"})
      throw("Error during operation")
    catch
      error ->
        Log.trace("Error: #{error}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "tryCatchFinally"})
    after
      Log.trace("Cleaning up resource", %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "tryCatchFinally"})
    end

    try do
      Log.trace("Normal operation", %{:file_name => "Main.hx", :line_number => 74, :class_name => "Main", :method_name => "tryCatchFinally"})
    catch
      _ ->
        nil
    after
      Log.trace("Cleanup always runs", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "tryCatchFinally"})
    end

    Log.trace("After try-catch block", %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "tryCatchFinally"})
  end

  def nested_try_catch() do
    try do
      Log.trace("Outer try", %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "nestedTryCatch"})
      try do
        Log.trace("Inner try", %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "nestedTryCatch"})
        throw("Inner error")
      catch
        error ->
          Log.trace("Inner catch: #{error}", %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "nestedTryCatch"})
          throw("Rethrow from inner")
      end
    catch
      error ->
        Log.trace("Outer catch: #{error}", %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "nestedTryCatch"})
    end
  end

  def custom_exception() do
    try do
      raise %{message: "Custom error", code: 404}
    rescue
      e ->
        Log.trace("Custom exception: #{inspect(e)}", %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "customException"})
    end
  end

  def divide(a, b) do
    if b == 0 do
      raise ArgumentError, "Division by zero"
    end
    a / b
  end

  def test_division() do
    try do
      result = divide(10, 2)
      Log.trace("10 / 2 = #{result}", %{:file_name => "Main.hx", :line_number => 117, :class_name => "Main", :method_name => "testDivision"})

      result = divide(10, 0)
      Log.trace("This won't execute", %{:file_name => "Main.hx", :line_number => 120, :class_name => "Main", :method_name => "testDivision"})
    rescue
      e in ArgumentError ->
        Log.trace("Division error: #{e.message}", %{:file_name => "Main.hx", :line_number => 122, :class_name => "Main", :method_name => "testDivision"})
    end
  end

  def rethrow_example() do
    inner_function = fn -> raise "Original error" end

    middle_function = fn ->
      try do
        inner_function.()
      rescue
        e ->
          Log.trace("Middle caught: #{inspect(e)}", %{:file_name => "Main.hx", :line_number => 136, :class_name => "Main", :method_name => "rethrowExample"})
          reraise e, __STACKTRACE__
      end
    end

    try do
      middle_function.()
    rescue
      e ->
        Log.trace("Outer caught rethrown: #{inspect(e)}", %{:file_name => "Main.hx", :line_number => 144, :class_name => "Main", :method_name => "rethrowExample"})
    end
  end

  def stack_trace_example() do
    try do
      level3 = fn -> raise "Deep error" end
      level2 = fn -> level3.() end
      level1 = fn -> level2.() end
      level1.()
    rescue
      e ->
        Log.trace("Error: #{inspect(e)}", %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "stackTraceExample"})
        Log.trace("Stack would be printed here", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "stackTraceExample"})
    end
  end

  def try_as_expression() do
    value = try do
      String.to_integer("123")
    rescue
      _ -> 0
    end
    Log.trace("Parsed value: #{value}", %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "tryAsExpression"})

    value2 = try do
      String.to_integer("not a number")
    rescue
      _ -> -1
    end
    Log.trace("Failed parse value: #{value2}", %{:file_name => "Main.hx", :line_number => 176, :class_name => "Main", :method_name => "tryAsExpression"})
  end

  def main() do
    Log.trace("=== Basic Try-Catch ===", %{:file_name => "Main.hx", :line_number => 180, :class_name => "Main", :method_name => "main"})
    basic_try_catch()

    Log.trace("\n=== Multiple Catch ===", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "main"})
    multiple_catch()

    Log.trace("\n=== Try-Catch-Finally ===", %{:file_name => "Main.hx", :line_number => 186, :class_name => "Main", :method_name => "main"})
    try_catch_finally()

    Log.trace("\n=== Nested Try-Catch ===", %{:file_name => "Main.hx", :line_number => 189, :class_name => "Main", :method_name => "main"})
    nested_try_catch()

    Log.trace("\n=== Custom Exception ===", %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "main"})
    custom_exception()

    Log.trace("\n=== Division Test ===", %{:file_name => "Main.hx", :line_number => 195, :class_name => "Main", :method_name => "main"})
    test_division()

    Log.trace("\n=== Rethrow Example ===", %{:file_name => "Main.hx", :line_number => 198, :class_name => "Main", :method_name => "main"})
    rethrow_example()

    Log.trace("\n=== Stack Trace Example ===", %{:file_name => "Main.hx", :line_number => 201, :class_name => "Main", :method_name => "main"})
    stack_trace_example()

    Log.trace("\n=== Try as Expression ===", %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "main"})
    try_as_expression()
  end
end