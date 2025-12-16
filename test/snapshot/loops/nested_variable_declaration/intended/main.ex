defmodule Main do
  defp test_simple_nested_var() do
    Enum.find(0..(length(items) - 1), fn i -> i > 2 end)
  end
  defp test_reflect_fields_nested_var() do
    data = %{:user1 => %{:status => "active", :score => 10}, :user2 => %{:status => "inactive", :score => 5}, :user3 => %{:status => "active", :score => 15}}
    active_high_scorers = []
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {data}, (fn -> fn _, {data} ->
  if (0 < length(Reflect.fields(data))) do
    key = Reflect.fields(data)[0]
    user_data = Map.get(data, key)
    if (user_data.status == "active") do
      score = user_data.score
      if (score > 8), do: active_high_scorers = Enum.concat(active_high_scorers, [key])
    end
    {:cont, {data}}
  else
    {:halt, {data}}
  end
end end).())
    nil
  end
  defp test_deep_nesting() do
    Enum.find(0..(length(matrix) - 1), fn i -> length(i) > 0 end)
  end
end
