defmodule Main do
  def basic_try_catch() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Simple error"]
      nil
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Exception object")]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def multiple_catch() do
    test_error = fn type ->
      try do
        (case type do
          1 -> raise Reflaxe.Elixir.HaxeThrow, [value: "String error"]
          2 -> raise Reflaxe.Elixir.HaxeThrow, [value: 42]
          3 -> raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Exception error")]
          4 -> raise Reflaxe.Elixir.HaxeThrow, [value: %{:error => "Object error"}]
          _ -> nil
        end)
      rescue
        haxe_exception ->
          (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
            {e, _} when is_binary(e) -> nil
            {e, _} when is_integer(e) -> nil
            {e, _} when is_struct(e, Reflaxe.Exception) -> nil
            {_e, _} -> nil
          end)
      end
    end
    _ = test_error.(1)
    _ = test_error.(2)
    _ = test_error.(3)
    _ = test_error.(4)
    _ = test_error.(0)
  end
  def try_catch_finally() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Error during operation"]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    try do
      nil
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {_e, _} -> nil
        end)
    end
    nil
  end
  def nested_try_catch() do
    try do
      try do
        raise Reflaxe.Elixir.HaxeThrow, [value: "Inner error"]
      rescue
        haxe_exception ->
          (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
            {e, _} when is_binary(e) -> raise Reflaxe.Elixir.HaxeThrow, [value: "Rethrow from inner"]
            _ ->
              reraise(haxe_exception, __STACKTRACE__)
          end)
      end
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def custom_exception() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: CustomException.new("Custom error", 404)]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, CustomException) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def divide(a, b) do
    if (b == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Division by zero")]
    end
    a / b
  end
  def test_division() do
    try do
      result = divide(10, 2)
      result = divide(10, 0)
      nil
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def rethrow_example() do
    inner_function = fn -> raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Original error")] end
    middle_function = fn ->
      try do
        inner_function.()
      rescue
        haxe_exception ->
          (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
            {e, _} when is_struct(e, Reflaxe.Exception) -> raise Reflaxe.Elixir.HaxeThrow, [value: e]
            _ ->
              reraise(haxe_exception, __STACKTRACE__)
          end)
      end
    end
    try do
      middle_function.()
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def stack_trace_example() do
    try do
      level3 = fn -> raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Deep error")] end
      level2 = fn -> level3.() end
      level1 = fn -> level2.() end
      _ = level1.()
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def try_as_expression() do
    _value = try do
      (case Integer.parse("123") do
        {num, _} -> num
        :error -> nil
      end)
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {_e, _} -> 0
        end)
    end
    _value2 = try do
      (case Integer.parse("not a number") do
        {num, _} -> num
        :error -> nil
      end)
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {_e, _} -> -1
        end)
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
