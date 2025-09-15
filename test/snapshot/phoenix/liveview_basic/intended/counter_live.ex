defmodule CounterLive do
  use CounterLiveWeb, :live_view

  def mount(_params, _session, socket) do
    socket = Phoenix.LiveView.assign(socket, :count, 0)
    {:ok, socket}
  end

  def handle_event("increment", _params, socket) do
    count = socket.assigns.count
    socket = Phoenix.LiveView.assign(socket, :count, count + 1)
    {:noreply, socket}
  end

  def handle_event("decrement", _params, socket) do
    count = socket.assigns.count
    socket = Phoenix.LiveView.assign(socket, :count, count - 1)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Counter: <%= @count %></h1>
      <button phx-click="increment">+</button>
      <button phx-click="decrement">-</button>
    </div>
    """
  end
end