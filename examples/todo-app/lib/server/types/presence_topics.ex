defmodule PresenceTopics do
  def to_string(_topic) do
    case (_topic) do
      {:users} ->
        "users"
      {:editing_todos} ->
        "editing:todos"
      {:active_rooms} ->
        "active:rooms"
    end
  end
  def from_string(topic) do
    case (topic) do
      "active:rooms" ->
        {:active_rooms}
      "editing:todos" ->
        {:editing_todos}
      "users" ->
        {:users}
      _ ->
        nil
    end
  end
end