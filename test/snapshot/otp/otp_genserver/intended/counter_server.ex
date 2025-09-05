defmodule CounterServer do
  @count nil
  def init(_args) do
    %{:ok => %{:count => 0}}
  end
  def handle_call_get_count(_from, state) do
    %{:reply => state.count, :state => state}
  end
  def handle_call_increment(_from, state) do
    new_state = %{:count => state.count + 1}
    %{:reply => new_state[:count], :state => new_state}
  end
  def handle_cast_reset(_state) do
    %{:noreply => %{:count => 0}}
  end
  def handle_info(msg, state) do
    Log.trace("Received info: " <> Std.string(msg), %{:fileName => "CounterServer.hx", :lineNumber => 31, :className => "CounterServer", :methodName => "handle_info"})
    %{:noreply => state}
  end
end