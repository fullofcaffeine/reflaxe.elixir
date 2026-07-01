defmodule MyAppWeb.DeleteLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def new() do
    %{:__reflaxe_class__ => MyAppWeb.DeleteLive}
  end
  def mount(_params, _session, socket) do
    socket = Phoenix.Component.assign(socket, :count, 0)
    %{ok: socket}
    {:ok, socket}
  end
  def delete_todo(_id, socket) do
    todo = nil
    (case MyApp.Repo.delete(todo) do
      {:ok, _deleted} ->
        s2 = remove_todo_from_list(_id, socket)
        %{noreply: s2}
      {:error, _reason} -> %{noreply: socket}
    end)
  end
  defp remove_todo_from_list(_id_like, socket) do
    socket
  end
end
