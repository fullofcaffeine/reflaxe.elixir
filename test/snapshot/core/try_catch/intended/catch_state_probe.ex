defmodule CatchStateProbe do
  defp fail(mode) do
    if (mode == 1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "rejected"]
    end
    if (mode == 2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: 7]
    end
    if (mode == 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: 1.5]
    end
  end
  defp caught_flag(mode) do
    rejected = false
    rejected = try do
      fail(mode)
      rejected
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        rejected = (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_binary(error) ->
            rejected = error == "rejected"
            rejected
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
            rejected
        end)
        rejected
    end
    rejected
  end
  defp handler_shadow(mode) do
    result = 10
    result = try do
      fail(mode)
      result
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        result = (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_binary(error) ->
            result = if (error == "rejected"), do: 20, else: 30
            result
          {result_2, _} when is_integer(result_2) ->
            cond do
              result_2 != 7 -> raise Reflaxe.Elixir.HaxeThrow, [value: "Wrong handler value"]
              true -> nil
            end
            result
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
            result
        end)
        result
    end
    result
  end
  def main() do
    if (caught_flag(0) or not caught_flag(1)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Handler lost its outer flag or changed the normal path"]
    end
    if (handler_shadow(0) != 10 or handler_shadow(1) != 20 or handler_shadow(2) != 10) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Handler-local binding changed the outer value"]
    end
    propagated = try do
      caught_flag(2)
      false
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {value_2, _} when is_integer(value_2) -> value_2 == 7
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if (not propagated) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Unmatched exception did not propagate"]
    end
    float_propagated = try do
      handler_shadow(3)
      false
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {value_2, _} when is_float(value_2) or is_tuple(value_2) and tuple_size(value_2) == 2 and elem(value_2, 0) == Reflaxe.Elixir.HaxeFloat and (elem(value_2, 1) == :nan or elem(value_2, 1) == :positive_infinity or elem(value_2, 1) == :negative_infinity) ->
            Reflaxe.Elixir.HaxeFloat.eq(value_2, 1.5)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    if (not float_propagated) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Integer handler caught an unmatched floating-point error"]
    end
  end
end
