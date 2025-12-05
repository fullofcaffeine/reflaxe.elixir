defmodule CounterServer do
  def init(_struct, _args) do
    %{:ok => %{:count => 0}}
  end
  def handle_call_get_count(_struct, _from, state) do
    %{:reply => Map.get(state, :count), :state => state}
  end
  def handle_call_increment(_struct, _from, _state) do
    new_state = %{:count => Map.get(state, :count) + 1}
    %{:reply => new_state.count, :state => new_state}
  end
  def handle_cast_reset(_struct, _state) do
    %{:noreply => %{:count => 0}}
  end
  def handle_info(_struct, _msg, state) do
    %{:noreply => state}
  end
end
