defmodule CounterLive do
  use Phoenix.Component
  def mount(struct, _params, _session, socket) do
    socket = Phoenix.Component.assign(socket, "count", 0)
    %{:ok => socket}
  end
  def handle_event_increment(struct, _params, socket) do
    count = socket.assigns.count
    socket = Phoenix.Component.assign(socket, "count", count + 1)
    %{:noreply => socket}
  end
  def handle_event_decrement(struct, _params, socket) do
    count = socket.assigns.count
    socket = Phoenix.Component.assign(socket, "count", (count - 1))
    %{:noreply => socket}
  end
  def render(struct, _assigns) do
    "<div>\n\t\t  <h1>Counter: <%= @count %></h1>\n\t\t  <button phx-click=\"increment\">+</button>\n\t\t  <button phx-click=\"decrement\">-</button>\n\t\t</div>"
  end
end