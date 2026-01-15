defmodule CustomTags do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, CustomTags, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, CustomTags, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def my_widget() do
    __haxe_static_get__(:my_widget, "my-widget")
  end
  def my_widget(value) do
    __haxe_static_put__(:my_widget, value)
  end
end
