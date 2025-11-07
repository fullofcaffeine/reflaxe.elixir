defmodule Message do
  def todo_created(arg0) do
    {0, arg0}
  end
  def todo_updated(arg0) do
    {1, arg0}
  end
  def todo_deleted(arg0) do
    {2, arg0}
  end
  def system_alert(arg0) do
    {3, arg0}
  end
end
