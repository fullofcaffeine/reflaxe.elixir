defmodule server.live.TodoLiveEvent do
  def create_todo(arg0) do
    {:CreateTodo, arg0}
  end
  def toggle_todo(arg0) do
    {:ToggleTodo, arg0}
  end
  def delete_todo(arg0) do
    {:DeleteTodo, arg0}
  end
  def edit_todo(arg0) do
    {:EditTodo, arg0}
  end
  def save_todo(arg0) do
    {:SaveTodo, arg0}
  end
  def cancel_edit() do
    {:CancelEdit}
  end
  def filter_todos(arg0) do
    {:FilterTodos, arg0}
  end
  def sort_todos(arg0) do
    {:SortTodos, arg0}
  end
  def search_todos(arg0) do
    {:SearchTodos, arg0}
  end
  def toggle_tag(arg0) do
    {:ToggleTag, arg0}
  end
  def set_priority(arg0, arg1) do
    {:SetPriority, arg0, arg1}
  end
  def toggle_form() do
    {:ToggleForm}
  end
  def bulk_complete() do
    {:BulkComplete}
  end
  def bulk_delete_completed() do
    {:BulkDeleteCompleted}
  end
end