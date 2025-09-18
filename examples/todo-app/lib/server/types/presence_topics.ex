defmodule PresenceTopics do
  def to_string(topic) do
    temp_result = nil
    case (topic) do
      {:users} ->
        temp_result = "users"
      {:editing_todos} ->
        temp_result = "editing:todos"
      {:active_rooms} ->
        temp_result = "active:rooms"
    end
    tempResult
  end
  def from_string(topic) do
    temp_result = nil
    case (topic) do
      "active:rooms" ->
        temp_result = {:active_rooms}
      "editing:todos" ->
        temp_result = {:editing_todos}
      "users" ->
        temp_result = {:users}
      _ ->
        temp_result = nil
    end
    tempResult
  end
end