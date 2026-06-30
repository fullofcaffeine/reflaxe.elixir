defmodule PhoenixHxTodo.TodoStateTest do
  use ExUnit.Case
  test "create adds newest task first" do
    todos = PhoenixHxTodoHx.Live.TodoState.seed("Guest Workspace")
    updated = PhoenixHxTodoHx.Live.TodoState.create(todos, 9, "  Port the board  ", " Keep the UX familiar ", "Guest Workspace")
    actual = length(updated)
    assert actual == 4
    actual = Enum.at(updated, 0).title
    assert actual == "Port the board"
    actual = Enum.at(updated, 0).notes
    assert actual == "Keep the UX familiar"
    condition = Enum.at(updated, 0).completed
    assert not condition
  end
  test "toggle and delete update state" do
    todos = PhoenixHxTodoHx.Live.TodoState.seed("Guest Workspace")
    toggled = PhoenixHxTodoHx.Live.TodoState.toggle(todos, 1)
    condition = Enum.at(toggled, 0).completed
    assert condition
    deleted = PhoenixHxTodoHx.Live.TodoState.delete_by_id(toggled, 1)
    actual = length(deleted)
    assert actual == 2
    actual = length(Enum.filter(deleted, fn todo -> todo.id == 1 end))
    assert actual == 0
  end
  test "stats separate open and completed" do
    stats = PhoenixHxTodoHx.Live.TodoState.stats(PhoenixHxTodoHx.Live.TodoState.seed("Guest Workspace"))
    actual = stats.open_count
    assert actual == 2
    actual = stats.completed_count
    assert actual == 1
    actual = stats.typed_column_count
    assert actual == 5
  end
end
