defmodule CounterLive do
  use Phoenix.LiveView
  
  import Phoenix.LiveView.Helpers
  import Ecto.Query
  alias TodoApp.Repo
  
  use Phoenix.Component
  import TodoAppWeb.CoreComponents
  
  @impl true
  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    socket = LiveView.assign(socket, "count", 0)
    %{"ok" => socket}
  end

  @doc "Generated from Haxe handle_event_increment"
  def handle_event_increment(params, socket) do
    count = socket.assigns.count
    socket = LiveView.assign(socket, "count", count + 1)
    %{"noreply" => socket}
  end

  @doc "Generated from Haxe handle_event_decrement"
  def handle_event_decrement(params, socket) do
    count = socket.assigns.count
    socket = LiveView.assign(socket, "count", count - 1)
    %{"noreply" => socket}
  end

  @impl true
  @doc "Generated from Haxe render"
  def render(assigns) do
    "<div>\n\t\t  <h1>Counter: <%= @count %></h1>\n\t\t  <button phx-click=\"increment\">+</button>\n\t\t  <button phx-click=\"decrement\">-</button>\n\t\t</div>"
  end

end
