defmodule TestAppWeb.GoldenLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    live = socket
    live = Phoenix.Component.assign(live, %{counter: 0, search_query: "", sort_by: "created", selected_tags: []})
    {:ok, live}
  end
  def handle_info(msg, socket) do
    live = socket
    next_socket = (case msg do
      {:external_increment, amount} ->
        Phoenix.Component.update(live, :counter, fn n -> n + amount end)
      {:external_reset} ->
        Phoenix.Component.assign(live, %{counter: 0, search_query: "", selected_tags: []})
    end)
    {:noreply, next_socket}
  end
  def render(assigns) do
    ~H"""
    <div id="golden-live">
      <h1>Counter: <%= Reflaxe.Elixir.HaxeFloat.to_string(@counter) %></h1>
      <p>Sort: <%= @sort_by %></p>
      <p>Query: <%= @search_query %></p>
      <p>Tags: <%= Reflaxe.Elixir.HaxeFloat.to_string(@selected_tags) %></p>
      <button phx-click="increment">+</button>
    </div>
    """
  end
  defp extract_id(params) do
    id_value = (case {params, "id"} do
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
    if (Kernel.is_nil(id_value)) do
      0
    else
      if (Kernel.is_integer(id_value)) do
        id_value
      else
        if (Kernel.is_binary(id_value)) do
          parsed = (case Integer.parse(id_value) do
            {num, _} -> num
            :error -> nil
          end)
          if (not Kernel.is_nil(parsed)), do: parsed, else: 0
        else
          0
        end
      end
    end
  end
  def handle_event(event, params, socket) do
    live = socket
    live = cond do
      event == "increment" ->
        live = Phoenix.Component.update(live, :counter, fn n -> n + 1 end)
        live
      event == "set_sort" ->
        sort_by_value = (case {params, "sort_by"} do
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
        live = Phoenix.Component.assign(live, :sort_by, (if (not Kernel.is_nil(sort_by_value)), do: sort_by_value, else: "created"))
        live
      event == "search" ->
        query_value = (case {params, "query"} do
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
        live = Phoenix.Component.assign(live, :search_query, (if (not Kernel.is_nil(query_value)), do: query_value, else: ""))
        live
      event == "toggle_tag" ->
        tag = (case {params, "tag"} do
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
        live = if (not Kernel.is_nil(tag)) do
          current_tags = socket.assigns.selected_tags
          updated_tags = if (Enum.member?(current_tags, tag)) do
            Enum.filter(current_tags, fn t -> t != tag end)
          else
            List.insert_at(current_tags, 0, tag)
          end
          Phoenix.Component.assign(live, :selected_tags, updated_tags)
        else
          live
        end
        live
      event == "set_priority" ->
        id = extract_id(params)
        live = Phoenix.Component.update(live, :counter, fn n -> n + id end)
        live
      true -> live
    end
    {:noreply, live}
  end
end
