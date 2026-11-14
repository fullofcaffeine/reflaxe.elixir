defmodule Tags_Fields_ do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Tags_Fields_, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Tags_Fields_, key}
    Process.put(static_key, {:set, value})
    value
  end
  def keep_private_tags() do
    __haxe_static_get__(:keep_private_tags, ["personal", "private"])
  end
  def keep_private_tags(value) do
    __haxe_static_put__(:keep_private_tags, value)
  end
  def is_private(tag) do
    (fn ->
      array_index_receiver_node_0 = Tags_Fields_.keep_private_tags()
      (case Enum.find_index(array_index_receiver_node_0, fn item -> item == tag end) do
        nil -> -1
        index -> index
      end)
    end).() >= 0
  end
end
