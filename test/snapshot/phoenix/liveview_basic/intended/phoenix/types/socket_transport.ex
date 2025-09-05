defmodule SocketTransport do
  def web_socket() do
    {:WebSocket}
  end
  def long_poll() do
    {:LongPoll}
  end
end