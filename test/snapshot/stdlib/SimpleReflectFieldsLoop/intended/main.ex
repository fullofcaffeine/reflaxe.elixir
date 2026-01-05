defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    _g = 0
    g_value = Reflect.fields(obj)
    _ = Enum.each(g_value, fn _ -> nil end)
  end
end
