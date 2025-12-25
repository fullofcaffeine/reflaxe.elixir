defmodule DeleteLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {DeleteLive.Layouts, :app}
  def mount(_params, session, socket) do
    socket = Phoenix.Component.assign(socket, :count, 0)
    %{:ok => socket}
    {:ok, socket}
  end
  def delete_todo(id, socket) do
    todo = nil
    (case MyApp.Repo.delete(todo) do
      {:ok, deleted} ->
        id = deleted
        s2 = remove_todo_from_list(id, socket)
        %{:noreply => s2}
      {:error, _reason} -> %{:noreply => socket}
    end)
  end
  defp remove_todo_from_list(id_like, socket) do
    socket
  end
end
