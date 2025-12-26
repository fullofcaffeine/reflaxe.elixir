defmodule Main do
  defp test_simple_nested_var() do
    items = [1, 2, 3, 4, 5]
    results = []
    i = 0
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {results, 0}, (fn -> fn _, {results, i} ->
      if (i < length(items)) do
        item = items[i]
        (old_i = i
i = i + 1
old_i)
        if (item > 2) do
          doubled = item * 2
          if (doubled > 6) do
            results = results ++ [doubled]
          end
        end
        {:cont, {results, i}}
      else
        {:halt, {results, i}}
      end
    end end).())
    nil
    nil
  end
  defp test_reflect_fields_nested_var() do
    data = %{:user1 => %{:status => "active", :score => 10}, :user2 => %{:status => "inactive", :score => 5}, :user3 => %{:status => "active", :score => 15}}
    active_high_scorers = []
    _g = 0
    _ = Reflect.fields(data)
    _ = Enum.each(g_value, (fn -> fn key ->
  user_data = Map.get(data, key)
  if (user_data.status == "active") do
    score = user_data.score
    if (score > 8) do
      active_high_scorers = active_high_scorers ++ [key]
    end
  end
end end).())
    nil
  end
  defp test_deep_nesting() do
    matrix = [[1, 2], [3, 4], [5, 6]]
    found = []
    i = 0
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {found, 0}, (fn -> fn _, {found, i} ->
      if (i < length(matrix)) do
        row = matrix[i]
        (old_i = i
i = i + 1
old_i)
        if (length(row) > 0) do
          j = 0
          {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {found, 0}, (fn -> fn _, {found, j} ->
            if (j < length(row)) do
              value = row[j]
              (old_j = j
j = j + 1
old_j)
              if (value > 2) do
                squared = value * value
                if (squared > 10) do
                  result = %{:original => value, :squared => squared}
                  _ = found ++ [result]
                end
              end
              {:cont, {found, j}}
            else
              {:halt, {found, j}}
            end
          end end).())
          nil
        end
        {:cont, {found, i}}
      else
        {:halt, {found, i}}
      end
    end end).())
    nil
    nil
  end
end
