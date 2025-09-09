defmodule CounterServer do
  @count nil
  def init(_struct, _args) do
    %{:ok => %{:count => 0}}
  end
  def handle_call_get_count(_struct, _from, state) do
    %{:reply => state.count, :state => state}
  end
  def handle_call_increment(_struct, _from, state) do
    new_state = %{:count => state.count + 1}
    %{:reply => new_state.count, :state => new_state}
  end
  def handle_cast_reset(_struct, _state) do
    %{:noreply => %{:count => 0}}
  end
  def handle_info(_struct, msg, state) do
    Log.trace("Received info: " <> Std.string(msg), %{:file_name => "CounterServer.hx", :line_number => 31, :class_name => "CounterServer", :method_name => "handle_info"})
    %{:noreply => state}
  end
end