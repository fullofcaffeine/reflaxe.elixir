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
    (case {m, "a"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
end
