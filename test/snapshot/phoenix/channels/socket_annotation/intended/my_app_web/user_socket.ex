defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket
  channel("typed:*", MyAppWeb.PingChannel)
  def connect(_, socket, _) do
    {:ok, socket}
  end
  def id(_) do
    nil
  end
end
