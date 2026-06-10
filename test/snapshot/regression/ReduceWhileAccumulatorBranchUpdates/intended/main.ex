defmodule Main do
  def main() do
    users = %{"a" => 0, "b" => 1, "c" => 2}
    names = []
    {_names} = Enum.reduce_while(Map.keys(users), {names}, fn k, {acc_names} ->
      try do
        acc_names = (if (k != "a") do
  v = Map.get(users, k)
  if (not Kernel.is_nil(v) and v > 0), do: acc_names ++ [k], else: acc_names
else
  acc_names
end)
        {:cont, {acc_names}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_names}}
        :throw, :continue ->
          {:cont, {acc_names}}
      end
    end)
    views = []
    {_views} = Enum.reduce_while(Map.keys(users), {views}, fn k, {acc_views} ->
      try do
        v = Map.get(users, k)
        acc_views = if (not Kernel.is_nil(v)), do: acc_views ++ [%{:key => k, :value => v}], else: acc_views
        {:cont, {acc_views}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_views}}
        :throw, :continue ->
          {:cont, {acc_views}}
      end
    end)
    nil
  end
end
