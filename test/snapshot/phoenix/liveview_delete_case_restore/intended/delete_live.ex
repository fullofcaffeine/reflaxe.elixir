defmodule DeleteLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {DeleteLive.Layouts, :app}
  def new() do
    %{}
  end
  def mount(_, _, socket) do
    socket = Phoenix.Component.assign(socket, :count, 0)
    %{:ok => socket}
    {:ok, socket}
  end
  def delete_todo(_, socket) do
    todo = nil
    (case MyApp.Repo.delete(todo) do
      {:ok, deleted} ->
        _s2 = remove_todo_from_list(deleted, socket)
        %{:noreply => deleted}
      {:error, _reason} -> %{:noreply => socket}
    end)
  end
  defp remove_todo_from_list(_, socket) do
    socket
  end
end
