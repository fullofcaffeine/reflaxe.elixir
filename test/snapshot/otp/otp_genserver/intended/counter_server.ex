defmodule CounterServer do
  def init(_, _) do
    %{:ok => %{:count => 0}}
  end
  def handle_call_get_count(_, _, state) do
    %{:reply => (case state do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "count") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :count)
    end)
end), :state => state}
  end
  def handle_call_increment(_, _, state) do
    new_state = %{:count => (case state do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "count") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :count)
    end)
end) + 1}
    %{:reply => new_state.count, :state => new_state}
  end
  def handle_cast_reset(_, _) do
    %{:noreply => %{:count => 0}}
  end
  def handle_info(_, _, state) do
    %{:noreply => state}
  end
end
