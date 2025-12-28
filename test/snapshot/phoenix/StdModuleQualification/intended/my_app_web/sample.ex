defmodule MyAppWeb.Sample do
  def main() do
    
  end
  def enum_map_guard() do
    xs = [1, 2, 3]
    ys = Enum.map(xs, fn x -> x + 1 end)
    ys[0]
  end
  def string_len_guard(s) do
    String.length(s)
  end
  def reflect_map_get() do
    m = %{}
    _a = Map.get(m, "a")
  end
end
