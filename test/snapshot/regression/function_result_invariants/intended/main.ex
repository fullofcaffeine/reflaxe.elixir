defmodule Main do
  def main() do
    cases = NativeResultCases.new()
    concrete = cases
    apply(Map.get(concrete, :__reflaxe_class__) || Map.get(concrete, :__struct__), :void_result, [concrete])
    StatementEffectProbe.reset()
    StatementEffectProbe.record(1)
    StatementEffectProbe.record(2)
    if (StatementEffectProbe.current() != 12) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "statement effects were dropped"]
    end
    StatementEffectProbe.reset()
    difference = (StatementEffectProbe.record(4) - StatementEffectProbe.record(1))
    if (difference != 3 or StatementEffectProbe.current() != 41) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "embedded call order changed"]
    end
    StatementEffectProbe.reset()
    if (StatementEffectProbe.tail_record(7) != 7 or StatementEffectProbe.current() != 7) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "tail call value lost"]
    end
    if (apply(Map.get(concrete, :__reflaxe_class__) || Map.get(concrete, :__struct__), :branch_value, [concrete, true]) != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "branch result lost"]
    end
    if (apply(Map.get(concrete, :__reflaxe_class__) || Map.get(concrete, :__struct__), :case_value, [concrete, 2]) != "two") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "case result lost"]
    end
    if (not Kernel.is_nil(apply(Map.get(concrete, :__reflaxe_class__) || Map.get(concrete, :__struct__), :nullable_string, [concrete, false]))) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "nullable result rejected"]
    end
    if (apply(Map.get(concrete, :__reflaxe_class__) || Map.get(concrete, :__struct__), :loop_carrier, [concrete, [1, 3, 5]]) != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "loop result carrier lost"]
    end
    if (apply(Map.get(cases, :__reflaxe_class__) || Map.get(cases, :__struct__), :callback_value, [cases, 6]) != 7) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "callback result lost"]
    end
  end
end
