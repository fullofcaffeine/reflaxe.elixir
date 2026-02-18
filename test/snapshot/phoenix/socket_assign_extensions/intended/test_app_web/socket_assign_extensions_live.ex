defmodule TestAppWeb.SocketAssignExtensionsLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    socket = socket |> Phoenix.Component.assign(%{:count => 0, :search_query => ""}) |> Phoenix.Component.assign(:count, 1) |> Phoenix.Component.update(:count, fn n -> n + 1 end) |> Phoenix.Component.assign_new(:search_query, fn -> "initial" end)
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
<div>socket-assign-extensions</div>
"""
  end
  def handle_event(event, params, socket) do
    switch_result_1 = (case event do
      "inc" -> {:noreply, Phoenix.Component.update(socket, :count, fn n -> n + 1 end)}
      "search" ->
        query = (case {params, "q"} do
          {reflect_obj, reflect_field} ->
            (case Map.fetch(reflect_obj, reflect_field) do
              {:ok, reflect_value} -> reflect_value
              _ ->
                (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
                  nil -> nil
                  reflect_atom ->
                    Map.get(reflect_obj, reflect_atom)
                end)
            end)
        end)
        {:noreply, Phoenix.Component.assign(socket, :search_query, (if (not Kernel.is_nil(query)), do: query, else: ""))}
      _ -> {:noreply, socket}
    end)
    switch_result_1
  end
end
