defmodule Message do
  def todo_created(arg0) do
    {:TodoCreated, arg0}
  end
  def todo_updated(arg0) do
    {:TodoUpdated, arg0}
  end
  def todo_deleted(arg0) do
    {:TodoDeleted, arg0}
  end
  def system_alert(arg0) do
    {:SystemAlert, arg0}
  end
end