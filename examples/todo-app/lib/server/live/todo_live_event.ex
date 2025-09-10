defmodule Server.Live.TodoLiveEvent do
  def create_todo(arg0) do
    {0, arg0}
  end
  def toggle_todo(arg0) do
    {1, arg0}
  end
  def delete_todo(arg0) do
    {2, arg0}
  end
  def edit_todo(arg0) do
    {3, arg0}
  end
  def save_todo(arg0) do
    {4, arg0}
  end
  def cancel_edit() do
    {5}
  end
  def filter_todos(arg0) do
    {6, arg0}
  end
  def sort_todos(arg0) do
    {7, arg0}
  end
  def search_todos(arg0) do
    {8, arg0}
  end
  def toggle_tag(arg0) do
    {9, arg0}
  end
  def set_priority(arg0, arg1) do
    {10, arg0, arg1}
  end
  def toggle_form() do
    {11}
  end
  def bulk_complete() do
    {12}
  end
  def bulk_delete_completed() do
    {13}
  end
end