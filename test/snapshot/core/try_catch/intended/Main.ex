defmodule Main do
  def basic_try_catch() do
    try do
      throw("Simple error")
      nil
    rescue
      e ->
        nil
    end
    try do
      throw(Exception.new("Exception object"))
    rescue
      e ->
        nil
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
          _ -> nil
        end)
      rescue
        e ->
          nil
        e ->
          nil
        e ->
          nil
        e ->
          nil
      end
    end
    _ = test_error.(1)
    _ = test_error.(2)
    _ = test_error.(3)
    _ = test_error.(4)
    _ = test_error.(0)
  end
  def try_catch_finally() do
    resource = "resource"
    try do
      throw("Error during operation")
    rescue
      e ->
        nil
    end
    try do
      nil
    rescue
      e ->
        nil
    end
    nil
  end
  def nested_try_catch() do
    try do
      try do
        throw("Inner error")
      rescue
        e ->
          throw("Rethrow from inner")
      end
    rescue
      e ->
        nil
    end
  end
  def custom_exception() do
    try do
      throw(CustomException.new("Custom error", 404))
    rescue
      e ->
        nil
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
      result = divide(10, 0)
      nil
    rescue
      e ->
        nil
    end
  end
  def rethrow_example() do
    inner_function = fn -> throw(Exception.new("Original error")) end
    middle_function = fn ->
      try do
        inner_function.()
      rescue
        e ->
          throw(e)
      end
    end
    try do
      middle_function.()
    rescue
      e ->
        nil
    end
  end
  def stack_trace_example() do
    try do
      level3 = fn -> throw(Exception.new("Deep error")) end
      level2 = fn -> level3.() end
      level1 = fn -> level2.() end
      _ = level1.()
    rescue
      e ->
        nil
    end
  end
  def try_as_expression() do
    value = try do
      (case Integer.parse("123") do
        {num, _} -> num
        :error -> nil
      end)
    rescue
      e ->
        0
    end
    value2 = try do
      (case Integer.parse("not a number") do
        {num, _} -> num
        :error -> nil
      end)
    rescue
      e ->
        -1
    end
    nil
  end
  def main() do
    _ = basic_try_catch()
    _ = multiple_catch()
    _ = try_catch_finally()
    _ = nested_try_catch()
    _ = custom_exception()
    _ = test_division()
    _ = rethrow_example()
    _ = stack_trace_example()
    _ = try_as_expression()
  end
end
