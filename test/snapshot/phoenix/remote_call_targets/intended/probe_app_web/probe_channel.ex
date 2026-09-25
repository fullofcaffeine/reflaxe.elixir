defmodule ProbeAppWeb.ProbeChannel do
  use ProbeAppWeb, :channel
  def join(_topic, _payload, socket) do
    {:ok, socket}
  end
  def direct(socket) do
    Phoenix.Socket.assign(socket, :erlang.binary_to_atom("fixed"), "plain")
  end
  def nested(socket, admission) do
    (case admission do
      {:denied} -> socket
      {:granted, reference} ->
        socket = socket |> Phoenix.Socket.assign(:erlang.binary_to_atom("fixed"), reference) |> Phoenix.Socket.assign(:erlang.binary_to_atom("other"), "second")
        socket
    end)
  end
end
