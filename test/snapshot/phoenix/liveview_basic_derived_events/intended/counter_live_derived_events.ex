defmodule CounterLiveDerivedEvents do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {CounterLiveDerivedEvents.Layouts, :app}
  def mount(_params, _session, socket) do
    socket = Phoenix.Component.assign(socket, :count, 0)
    {:ok, socket}
  end
  def render(_struct, assigns) do
    ~H"""
<div>
          <h1>Counter: <%= Reflaxe.Elixir.HaxeFloat.to_string(@count) %></h1>
          <button phx-click="increment">+</button>
          <button phx-click="decrement">-</button>
        </div>
"""
  end
  def handle_event(event, _params, socket) do
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
