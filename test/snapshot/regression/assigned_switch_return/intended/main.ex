defmodule Main do
  defp decide(operation, exists) do
    (case operation do
      {:put, id} ->
        cond do
          id != "ok" -> "rejected"
          true ->
            value = "payload"
            "saved:" <> value
        end
      {:remove} ->
        if (not exists) do
          "missing"
        else
          value = "deleted"
          "saved:#{value}"
        end
    end)
  end
  def conditional_value(kind) do
    cond do
      kind == 0 -> 90
      kind == 1 ->
        value = 10
        _ = value + 1
      true -> 80
    end
  end
  def protected_conditional(kind) do
    try do
      cond do
        kind == 0 -> 90
        kind == 1 ->
          value = 10
          _ = value + 1
        true -> 80
      end
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_struct(error, Reflaxe.Exception) or is_map(error) and is_map_key(error, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, error) == Reflaxe.Exception -> -1
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def conditional_effects(kind, observe) do
    cond do
      observe.(kind) == 0 -> 90
      observe.(kind + 10) == 11 ->
        observe.(20)
        observe.(30)
      true -> 80
    end
  end
  def implicit_else(kind, observe) do
    cond do
      kind == 0 -> 90
      kind == 1 ->
        observe.(20)
        observe.(30)
      true -> observe.(30)
    end
  end
  def conditional_closure(kind) do
    cond do
      kind == 0 ->
        callback = fn -> 40 end
        value = callback.()
        _ = value + 1
      kind == 1 -> 90
      true ->
        value = 10
        _ = value + 1
    end
  end
  def protected_throw(kind) do
    try do
      cond do
        kind == 0 -> 90
        kind == 1 ->
          value = may_fail(kind)
          if (kind == 2) do
            raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("continuation", nil, nil)]
          end
          _ = value + 1
        true ->
          value = 10
          if (kind == 2) do
            raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("continuation", nil, nil)]
          end
          _ = value + 1
      end
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_struct(error, Reflaxe.Exception) or is_map(error) and is_map_key(error, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, error) == Reflaxe.Exception -> -1
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp may_fail(kind) do
    if (kind == 1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("branch", nil, nil)]
    end
    10
  end
  def main() do
    expected = 90
    if (conditional_value(0) != expected or protected_conditional(0) != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conditional return did not exit its function."]
    end
    expected = 11
    if (conditional_value(1) != expected or protected_conditional(1) != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conditional return did not exit its function."]
    end
    expected = 80
    if (conditional_value(2) != expected or protected_conditional(2) != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conditional return did not exit its function."]
    end
    if (conditional_closure(0) != 41 or conditional_closure(1) != 90 or conditional_closure(2) != 11) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conditional closure changed return ownership."]
    end
    if (protected_throw(0) != 90 or protected_throw(1) != -1 or protected_throw(2) != -1 or protected_throw(3) != 11) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conditional continuation changed its catch scope."]
    end
    if (decide({:put, "bad"}, true) != "rejected") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Switch return did not exit the function."]
    end
    if (decide({:remove}, false) != "missing") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Missing-document return did not exit the function."]
    end
    if (decide({:put, "ok"}, true) != "saved:payload") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Valid write changed."]
    end
    if (decide({:remove}, true) != "saved:deleted") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Valid delete changed."]
    end
    if (nested({:put, "bad"}, true) != "outer") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Outer switch exit changed."]
    end
    if (nested({:put, "ok"}, false) != "inner") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested switch exit changed."]
    end
    if (nested({:put, "ok"}, true) != "saved:inside") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested normal continuation changed."]
    end
    if (closure_value(true) != "saved:closure") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Closure return escaped its function."]
    end
    if (closure_value(false) != "saved:other") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Normal alternate branch changed."]
    end
  end
  defp nested(operation, exists) do
    (case operation do
      {:put, id} ->
        if (id != "ok") do
          "outer"
        else
          (case operation do
            {:put, _} ->
              if (not exists) do
                "inner"
              else
                inner = "inside"
                value = inner
                "saved:#{value}"
              end
            {:remove} ->
              inner = "unused"
              value = inner
              "saved:#{value}"
          end)
        end
      {:remove} ->
        value = "removed"
        "saved:#{value}"
    end)
  end
  defp closure_value(selected) do
    value = if (selected) do
      callback = fn -> "closure" end
      callback.()
    else
      "other"
    end
    "saved:#{value}"
  end
end
