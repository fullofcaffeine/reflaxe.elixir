defmodule CounterServer do
  def init(_struct, _args) do
    %{:ok => %{:count => 0}}
  end
  def handle_call_get_count(_struct, _from, state) do
    %{:reply => (case state do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "count") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :count)
    end)
end), :state => state}
  end
  def handle_call_increment(_struct, _from, state) do
    new_state = %{:count => Reflaxe.Elixir.HaxeFloat.add(((case state do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "count") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :count)
    end)
end)), 1)}
    %{:reply => new_state.count, :state => new_state}
  end
  def handle_cast_reset(_struct, _state) do
    %{:noreply => %{:count => 0}}
  end
  def handle_info(_struct, _msg, state) do
    %{:noreply => state}
  end
end
