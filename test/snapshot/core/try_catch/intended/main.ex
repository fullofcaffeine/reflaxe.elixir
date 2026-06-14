defmodule Main do
  def basic_try_catch() do
    caught_string = try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Simple error"]
      ""
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> e
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if ("Simple error" != caught_string) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: basicTryCatch string catch (expected \"Simple error\", got \"" <> caught_string <> "\")"]
    end
    caught_exception_message = try do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Exception object", nil, nil)]
      ""
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == Reflaxe.Exception ->
            Reflaxe.Exception.get_message(e)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if ("Exception object" != caught_exception_message) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: basicTryCatch Exception catch (expected \"Exception object\", got \"" <> caught_exception_message <> "\")"]
    end
  end
  def multiple_catch() do
    test_error = fn type ->
      outcome = try do
        (case type do
          1 -> raise Reflaxe.Elixir.HaxeThrow, [value: "String error"]
          2 -> raise Reflaxe.Elixir.HaxeThrow, [value: 42]
          3 -> raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Exception error", nil, nil)]
          4 -> raise Reflaxe.Elixir.HaxeThrow, [value: %{:error => "Object error"}]
          _ -> "none"
        end)
      rescue
        haxe_exception ->
          Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
          (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
            {e, _} when is_binary(e) -> "string:" <> e
            {e, _} when is_integer(e) -> "int:" <> Kernel.to_string(e)
            {e, _} when is_struct(e, Reflaxe.Exception) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == Reflaxe.Exception -> "exception:" <> Reflaxe.Exception.get_message(e)
            {_e, _} -> "dynamic"
          end)
      end
      expected = cond do
        type == 1 -> "string:String error"
        type == 2 -> "int:42"
        type == 3 -> "exception:Exception error"
        type == 4 -> "dynamic"
        :true -> "none"
      end
      if (expected != outcome) do
        raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: " <> "multipleCatch type=" <> Kernel.to_string(type) <> " (expected \"" <> expected <> "\", got \"" <> outcome <> "\")"]
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
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
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
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
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
    caught_outer = try do
      try do
        raise Reflaxe.Elixir.HaxeThrow, [value: "Inner error"]
      rescue
        haxe_exception ->
          Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
          (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
            {e, _} when is_binary(e) -> raise Reflaxe.Elixir.HaxeThrow, [value: "Rethrow from inner"]
            _ ->
              reraise(haxe_exception, __STACKTRACE__)
          end)
      end
      "no_error"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> e
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if ("Rethrow from inner" != caught_outer) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: nestedTryCatch outer catch (expected \"Rethrow from inner\", got \"" <> caught_outer <> "\")"]
    end
  end
  def custom_exception() do
    outcome = try do
      raise Reflaxe.Elixir.HaxeThrow, [value: CustomException.new("Custom error", 404)]
      "no_error"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, CustomException) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == CustomException -> "" <> Reflaxe.Exception.get_message(e) <> ":" <> Kernel.to_string(e.code)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if ("Custom error:404" != outcome) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: customException (expected \"Custom error:404\", got \"" <> outcome <> "\")"]
    end
  end
  def divide(a, b) do
    if (b == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Division by zero", nil, nil)]
    end
    a / b
  end
  def test_division() do
    ok = divide(10, 2)
    if (ok != 5) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: divide(10, 2) == 5"]
    end
    caught_division_message = try do
      _ = divide(10, 0)
      "no_error"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == Reflaxe.Exception ->
            Reflaxe.Exception.get_message(e)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if ("Division by zero" != caught_division_message) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: divide(10, 0) throws (expected \"Division by zero\", got \"" <> caught_division_message <> "\")"]
    end
  end
  def rethrow_example() do
    message = try do
      try do
        raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Original error", nil, nil)]
      rescue
        haxe_exception ->
          Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
          (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
            {e, _} when is_struct(e, Reflaxe.Exception) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == Reflaxe.Exception -> raise Reflaxe.Elixir.HaxeThrow, [value: e]
            _ ->
              reraise(haxe_exception, __STACKTRACE__)
          end)
      end
      "no_error"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == Reflaxe.Exception ->
            Reflaxe.Exception.get_message(e)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if ("Original error" != message) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: rethrowExample rethrow preserves value (expected \"Original error\", got \"" <> message <> "\")"]
    end
  end
  def stack_trace_example() do
    caught_message = try do
      level3 = fn -> raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Deep error", nil, nil)] end
      level2 = fn -> level3.() end
      level1 = fn -> level2.() end
      _ = level1.()
      "no_error"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Reflaxe.Exception) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == Reflaxe.Exception ->
            Reflaxe.Exception.get_message(e)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if ("Deep error" != caught_message) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: stackTraceExample message (expected \"Deep error\", got \"" <> caught_message <> "\")"]
    end
  end
  def try_as_expression() do
    value = try do
      parsed = (case Integer.parse("123") do
        {num, _} -> num
        :error -> nil
      end)
      if (Kernel.is_nil(parsed)) do
        raise Reflaxe.Elixir.HaxeThrow, [value: "parseInt failed"]
      end
      parsed
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {_e, _} -> 0
        end)
    end
    if (123 != value) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: tryAsExpression parseInt(123) (expected " <> Kernel.to_string(123) <> ", got " <> Kernel.to_string(value) <> ")"]
    end
    value_value = try do
      parsed = (case Integer.parse("not a number") do
        {num, _} -> num
        :error -> nil
      end)
      if (Kernel.is_nil(parsed)) do
        raise Reflaxe.Elixir.HaxeThrow, [value: "parseInt failed"]
      end
      parsed
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {_e, _} -> -1
        end)
    end
    if (-1 != value_value) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: tryAsExpression throws and returns fallback (expected " <> Kernel.to_string(-1) <> ", got " <> Kernel.to_string(value_value) <> ")"]
    end
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
