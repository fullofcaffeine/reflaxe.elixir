defmodule CounterLive do
  use Phoenix.Component
  use CounterLiveWeb, :live_view
  require Ecto.Query
  def mount(_params, session, socket) do
    socket = Phoenix.Component.assign(socket, "count", 0)
    %{:ok => socket}
    {:ok, socket}
  end
  def handle_event_increment(struct, value, socket) do
    count = socket.assigns.count
    socket = Phoenix.Component.assign(socket, "count", count + 1)
    %{:noreply => socket}
  end
  def handle_event_decrement(struct, value, socket) do
    count = socket.assigns.count
    socket = Phoenix.Component.assign(socket, "count", (count - 1))
    %{:noreply => socket}
  end
  def render(struct, assigns) do
    ~H"""
<div>
          <h1>Counter: <%= @count %></h1>
          <button phx-click="increment">+</button>
          <button phx-click="decrement">-</button>
        </div>
"""
  end
end
