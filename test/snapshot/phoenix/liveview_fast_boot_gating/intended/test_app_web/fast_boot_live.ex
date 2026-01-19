defmodule TestAppWeb.FastBootLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    socket = socket |> Phoenix.Component.assign(:count, 0) |> Phoenix.Component.assign(:active, false)
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
<div>
  <span data-testid="count"><%= @count %></span>
  <span data-testid="status" class={if @active, do: "on", else: "off"}>status</span>
</div>
"""
  end
  def handle_event(event, _params, socket) do
    socket = (case event do
      "increment" ->
        next = socket.assigns.count + 1
        socket = Phoenix.Component.assign(socket, :count, next)
        socket
      "toggle" ->
        socket = Phoenix.Component.assign(socket, :active, not socket.assigns.active)
        socket
      _ ->
        nil
        socket
    end)
    {:noreply, socket}
  end
end
