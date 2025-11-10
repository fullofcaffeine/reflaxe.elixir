defmodule SafeAssigns do
  def set_editing_todo(socket, todo) do
    Phoenix.Component.assign(socket, :editing_todo, todo)
  end
  def set_selected_tags(socket, tags) do
    Phoenix.Component.assign(socket, :selected_tags, tags)
  end
  def set_filter(socket, filter) do
    Phoenix.Component.assign(socket, :filter, (case filter do
  "active" -> {:active}
  "completed" -> {:completed}
  _ -> {:all}
end))
  end
  def set_sort_by_and_resort(socket, sort_by) do
    Phoenix.Component.assign(socket, :sort_by, (case sort_by do
  "due_date" -> {:due_date}
  "priority" -> {:priority}
  _ -> {:created}
end))
  end
  def set_search_query(socket, query) do
    Phoenix.Component.assign(socket, :search_query, query)
  end
  def set_show_form(socket, show_form) do
    Phoenix.Component.assign(socket, :show_form, show_form)
  end
end
