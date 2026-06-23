defmodule TestAppWeb.StreamTokensLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    socket = socket |> Phoenix.LiveView.stream(:todos, seed_todos()) |> Phoenix.LiveView.stream(:notices, ["ready"]) |> Phoenix.LiveView.stream(:legacy_todos, seed_todos())
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
<ul id="todos" phx-update="stream"></ul>
"""
  end
  defp seed_todos() do
    [todo(1, "First")]
  end
  defp todo(id, title) do
    %{:id => id, :title => title}
  end
  def handle_event(event, _params, socket) do
    switch_result_1 = (case event do
      "add" -> {:noreply, Phoenix.LiveView.stream_insert(socket, :todos, todo(2, "Next"))}
      "delete" -> {:noreply, Phoenix.LiveView.stream_delete(socket, :todos, todo(1, "First"))}
      "notice" -> {:noreply, Phoenix.LiveView.stream_insert(socket, :notices, "Saved")}
      _ -> {:noreply, socket}
    end)
    switch_result_1
  end
end
