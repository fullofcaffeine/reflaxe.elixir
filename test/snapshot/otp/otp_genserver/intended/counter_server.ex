defmodule CounterServer do
  def init(struct, args) do
    %{:ok => %{:count => 0}}
  end
  def handle_call_get_count(struct, from, state) do
    %{:reply => Map.get(state, :count), :state => state}
  end
  def handle_call_increment(struct, from, state) do
    new_state = %{:count => Map.get(state, :count) + 1}
    %{:reply => new_state.count, :state => new_state}
  end
  def handle_cast_reset(struct, state) do
    %{:noreply => %{:count => 0}}
  end
  def handle_info(struct, msg, state) do
    _ = Log.trace("Received info: #{(fn -> inspect(msg) end).()}", %{:file_name => "CounterServer.hx", :line_number => 31, :class_name => "CounterServer", :method_name => "handle_info"})
    %{:noreply => state}
  end
end
