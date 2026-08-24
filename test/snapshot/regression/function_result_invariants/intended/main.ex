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
    this1 = 1
    flags = this1
    if (Bitwise.band(flags, 1) == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "statements after an inline abstract reassignment were dropped"]
    end
    flags = Bitwise.bor(flags, 2)
    if (Bitwise.band(flags, 2) == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "statements after an inline abstract mutation were dropped"]
    end
    unsigned_counter = -1
    {unsigned_counter, reflaxe_call_value_0} = (fn ->
      old = unsigned_counter
      unsigned_counter = (
            case Bitwise.band(unsigned_counter + 1, 0xFFFFFFFF) do
              v when v >= 0x80000000 -> v - 0x100000000
              v -> v
            end
      )
      {unsigned_counter, old}
    end).()
    if (reflaxe_call_value_0 != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "inline abstract post-increment returned the wrong prior value"]
    end
    if (unsigned_counter != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "inline abstract post-increment did not rebind its caller"]
    end
    old = 99
    unsigned_counter = -1
    {unsigned_counter, reflaxe_call_value_1} = (fn ->
      old = unsigned_counter
      unsigned_counter = (
            case Bitwise.band(unsigned_counter + 1, 0xFFFFFFFF) do
              v when v >= 0x80000000 -> v - 0x100000000
              v -> v
            end
      )
      {unsigned_counter, old}
    end).()
    if (identity_int(reflaxe_call_value_1) != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "function argument post-increment returned the wrong prior value"]
    end
    if (unsigned_counter != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "function argument post-increment did not rebind its caller"]
    end
    if (old != 99) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "inline abstract temporary escaped into the caller"]
    end
  end
  defp identity_int(value) do
    value
  end
end
