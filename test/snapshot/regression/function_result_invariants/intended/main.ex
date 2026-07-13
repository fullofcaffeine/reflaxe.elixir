defmodule Main do
  def main() do
    cases = NativeResultCases.new()
    concrete = cases
    _ = apply(Map.get(concrete, :__reflaxe_class__) || Map.get(concrete, :__struct__), :void_result, [concrete])
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
