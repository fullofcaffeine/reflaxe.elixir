defmodule CounterLiveDerivedEvents do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {CounterLiveDerivedEvents.Layouts, :app}
  def mount(_, _, socket) do
    socket = Phoenix.Component.assign(socket, :count, 0)
    {:ok, socket}
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
  def handle_event(event, _, socket) do
    (case event do
      "decrement" ->
        next_count = (socket.assigns.count - 1)
        {:noreply, Phoenix.Component.assign(socket, :count, next_count)}
      "increment" ->
        next_count = socket.assigns.count + 1
        {:noreply, Phoenix.Component.assign(socket, :count, next_count)}
      _ -> {:noreply, socket}
    end)
  end
end
