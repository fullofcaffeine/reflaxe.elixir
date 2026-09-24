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
  def events() do
    __haxe_static_get__(:events, "")
  end
  def events(value) do
    __haxe_static_put__(:events, value)
  end
  defp buffer() do
    Main.events("#{Main.events()}B")
    StringBuf.new()
  end
  defp text() do
    Main.events("#{Main.events()}A")
    "text"
  end
  defp values() do
    Main.events("#{Main.events()}L")
    result = Haxe.Ds.List.new()
    result = apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :add, [result, 7])
    result = apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :add, [result, 9])
    result
  end
  defp item() do
    Main.events("#{Main.events()}I")
    7
  end
  defp assert_true(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    reflaxe_dispatch_receiver_node_0 = buffer()
    _ = apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :add, [reflaxe_dispatch_receiver_node_0, text()])
    assert_true(Main.events() == "BA", "Evaluate receiver once before argument")
    reflaxe_dispatch_receiver_node_1 = values()
    {_reflaxe_dispatch_receiver_node_1, reflaxe_receiver_value_0} = apply(Map.get(reflaxe_dispatch_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_1, :__struct__), :pop, [reflaxe_dispatch_receiver_node_1])
    assert_true(reflaxe_receiver_value_0 == 7, "Preserve the companion return value")
    reflaxe_dispatch_receiver_node_2 = values()
    {_reflaxe_dispatch_receiver_node_2, reflaxe_receiver_value_1} = apply(Map.get(reflaxe_dispatch_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_2, :__struct__), :remove, [reflaxe_dispatch_receiver_node_2, item()])
    assert_true(reflaxe_receiver_value_1, "Preserve boolean companion result")
    assert_true(Main.events() == "BALLI", "Companion calls must retain receiver and argument order")
    local_buffer = StringBuf.new()
    local_buffer = apply(Map.get(local_buffer, :__reflaxe_class__) || Map.get(local_buffer, :__struct__), :add, [local_buffer, "left"])
    local_buffer = apply(Map.get(local_buffer, :__reflaxe_class__) || Map.get(local_buffer, :__struct__), :add, [local_buffer, "right"])
    assert_true(apply(Map.get(local_buffer, :__reflaxe_class__) || Map.get(local_buffer, :__struct__), :to_string, [local_buffer]) == "leftright", "Keep direct-local receiver updates")
    local_values = values()
    {local_values, reflaxe_receiver_value_2} = apply(Map.get(local_values, :__reflaxe_class__) || Map.get(local_values, :__struct__), :pop, [local_values])
    assert_true(reflaxe_receiver_value_2 == 7, "Keep the first local companion value")
    {local_values, reflaxe_receiver_value_3} = apply(Map.get(local_values, :__reflaxe_class__) || Map.get(local_values, :__struct__), :pop, [local_values])
    assert_true(reflaxe_receiver_value_3 == 9, "Keep local state after companion return")
    assert_true(apply(Map.get(local_values, :__reflaxe_class__) || Map.get(local_values, :__struct__), :is_empty, [local_values]), "Local receiver must retain both removals")
  end
end
