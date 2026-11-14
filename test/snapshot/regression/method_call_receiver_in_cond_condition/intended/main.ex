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
  def whole_number() do
    __haxe_static_get__(:whole_number, EReg.new("^[1-9][0-9]{0,8}$", ""))
  end
  def whole_number(value) do
    __haxe_static_put__(:whole_number, value)
  end
  def main() do

  end
  def guard_with_new_regex(value) do
    (case value do
      {:number_value, canonical} ->
        cond do
          (fn ->
            reflaxe_dispatch_receiver_node_0 = EReg.new("^[1-9][0-9]{0,8}$", "")
            apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :match, [reflaxe_dispatch_receiver_node_0, canonical])
          end).() -> Reflaxe.Elixir.HaxeInt.parse(canonical)
          true -> -1
        end
      _ -> -1
    end)
  end
  def guard_with_static_regex(value) do
    (case value do
      {:number_value, canonical} ->
        cond do
          (fn ->
            reflaxe_dispatch_receiver_node_1 = Main.whole_number()
            apply(Map.get(reflaxe_dispatch_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_1, :__struct__), :match, [reflaxe_dispatch_receiver_node_1, canonical])
          end).() -> Reflaxe.Elixir.HaxeInt.parse(canonical)
          true -> -1
        end
      _ -> -1
    end)
  end
  def condition_with_new_regex(value) do
    (case value do
      {:number_value, canonical} ->
        cond do
          (fn ->
            reflaxe_dispatch_receiver_node_2 = EReg.new("^[1-9][0-9]{0,8}$", "")
            apply(Map.get(reflaxe_dispatch_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_2, :__struct__), :match, [reflaxe_dispatch_receiver_node_2, canonical])
          end).() -> Reflaxe.Elixir.HaxeInt.parse(canonical)
          true -> -1
        end
      _ -> -2
    end)
  end
end
