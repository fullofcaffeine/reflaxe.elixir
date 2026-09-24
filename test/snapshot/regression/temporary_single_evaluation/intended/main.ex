defmodule Main do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Main, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Main, key}
    Process.put(static_key, {:set, value})
    value
  end
  def calls() do
    __haxe_static_get__(:calls, 0)
  end
  def calls(value) do
    __haxe_static_put__(:calls, value)
  end
  def events() do
    __haxe_static_get__(:events, "")
  end
  def events(value) do
    __haxe_static_put__(:events, value)
  end
  defp record(label) do
    Main.events("#{Main.events()}#{label}")
    String.length(Main.events())
  end
  defp check_order() do
    Main.events("")
    g = record("a")
    record("b")
    if (g != 1 or Main.events() != "ab") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A saved call moved past a later effect."]
    end
  end
  defp check_unused() do
    Main.events("")
    _g = record("a")
    if (Main.events() != "a") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "An unused result erased its effect."]
    end
  end
  defp check_captured_local() do
    source = 3
    g = source
    source = 9
    if (g != 3 or source != 9) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A saved local became a later read."]
    end
  end
  defp check_written_local() do
    g = 4
    g = g + 2
    g = g + 1
    if (g != 7) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Literal substitution erased later writes."]
    end
  end
  defp pair() do
    Main.calls(Main.calls() + 1)
    %{key: Main.calls(), value: Main.calls() * 10}
  end
  defp maybe_fail(should_fail) do
    record("a")
    if (should_fail) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "expected"]
    end
    0
  end
  defp caught_at_original_position() do
    try do
      g = maybe_fail(true)
      record("b")
      g == 0
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {message, _} when is_binary(message) -> message == "expected" and Main.events() == "a"
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp check_exception() do
    Main.events("")
    if (not caught_at_original_position()) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A saved call changed exception order."]
    end
    Main.events("")
    g = maybe_fail(false)
    record("b")
    if (g != 0 or Main.events() != "ab") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A successful call changed effect order."]
    end
  end
  defp check_literal_switch() do
    result = (case 2 do
      1 -> "one"
      2 -> "two"
      _ -> "other"
    end)
    if (result != "two" or false) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Stable literal substitution changed a switch."]
    end
  end
  defp missing_entry(items) do
    if ((length(items) != 3 or (case Enum.find_index(items, fn item -> item == "first" end) do
      nil -> -1
      index -> index
    end) < 0 or (case Enum.find_index(items, fn item -> item == "second" end) do
      nil -> -1
      index -> index
    end) < 0 or (case Enum.find_index(items, fn item -> item == "last" end) do
      nil -> -1
      index -> index
    end) < 0)), do: true, else: false
  end
  defp check_compound_condition() do
    if (not missing_entry(["first", "second", "wrong"])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "The final condition operand was lost."]
    end
    if (missing_entry(["first", "second", "last"])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A complete selection was rejected."]
    end
  end
  def main() do
    PatternBindingProbe.main()
    check_compound_condition()
    Main.calls(0)
    g = pair()
    key = g.key
    value = g.value
    if (Main.calls() != 1 or key != 1 or value != 10) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A captured pair must be evaluated once."]
    end
    check_order()
    check_unused()
    check_captured_local()
    check_written_local()
    check_exception()
    check_literal_switch()
  end
end
