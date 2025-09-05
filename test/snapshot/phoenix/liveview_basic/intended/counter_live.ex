defmodule CounterLive do
  use CounterLiveWeb, :live_view
  def mount(params, session, socket) do
    socket = Phoenix.LiveView.assign(socket, "count", 0)
    %{:ok => socket}
  end
  def handle_event_increment(params, socket) do
    count = socket.assigns.count
    socket = Phoenix.LiveView.assign(socket, "count", count + 1)
    %{:noreply => socket}
  end
  def handle_event_decrement(params, socket) do
    count = socket.assigns.count
    socket = Phoenix.LiveView.assign(socket, "count", (count - 1))
    %{:noreply => socket}
  end
  def render(assigns) do
    "<div>\n\t\t  <h1>Counter: <%= @count %></h1>\n\t\t  <button phx-click=\"increment\">+</button>\n\t\t  <button phx-click=\"decrement\">-</button>\n\t\t</div>"
  end
end