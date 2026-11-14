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
  def limit() do
    __haxe_static_get__(:limit, 3)
  end
  def limit(value) do
    __haxe_static_put__(:limit, value)
  end
  def main() do

  end
  def is_private_tag(tag) do
    Tags_Fields_.is_private(tag)
  end
  def under_limit(count) do
    count < Main.limit()
  end
end
