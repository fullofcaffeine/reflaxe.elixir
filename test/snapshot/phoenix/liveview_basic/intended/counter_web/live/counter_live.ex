defmodule CounterLive do
  use AppWeb, :live_view

  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    socket = Phoenix.Component.assign(Phoenix.LiveView, socket, "count", 0)

    %{ok: socket}
  end


  @doc "Generated from Haxe handle_event_increment"
  def handle_event_increment(_params, socket) do
    count = socket.assigns.count

    socket = Phoenix.Component.assign(Phoenix.LiveView, socket, "count", (count + 1))

    %{noreply: socket}
  end


  @doc "Generated from Haxe handle_event_decrement"
  def handle_event_decrement(_params, socket) do
    count = socket.assigns.count

    socket = Phoenix.Component.assign(Phoenix.LiveView, socket, "count", (count - 1))

    %{noreply: socket}
  end


  @doc "Generated from Haxe render"
  def render(assigns) do
    "<div>\n\t\t  <h1>Counter: <%= @count %></h1>\n\t\t  <button phx-click=\"increment\">+</button>\n\t\t  <button phx-click=\"decrement\">-</button>\n\t\t</div>"
  end


end
