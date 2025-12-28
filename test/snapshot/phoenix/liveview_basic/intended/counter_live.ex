defmodule CounterLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {CounterLive.Layouts, :app}
  def mount(_, _, socket) do
    socket = Phoenix.Component.assign(socket, :count, 0)
    {:ok, socket}
  end
  def handle_event_increment(_, _, socket) do
    count = socket.assigns.count
    socket = Phoenix.Component.assign(socket, :count, count + 1)
    {:noreply, socket}
  end
  def handle_event_decrement(_, _, socket) do
    count = socket.assigns.count
    socket = Phoenix.Component.assign(socket, :count, (count - 1))
    {:noreply, socket}
  end
  def render(_, assigns) do
    ~H"""
<div>
          <h1>Counter: <%= Kernel.to_string(@count) %></h1>
          <button phx-click="increment">+</button>
          <button phx-click="decrement">-</button>
        </div>
"""
  end
end
