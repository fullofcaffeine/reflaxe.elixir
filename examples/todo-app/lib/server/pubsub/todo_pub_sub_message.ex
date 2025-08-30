defmodule TodoPubSubMessage do
  def todo_created(arg0) do
    {:TodoCreated, arg0}
  end
  def todo_updated(arg0) do
    {:TodoUpdated, arg0}
  end
  def todo_deleted(arg0) do
    {:TodoDeleted, arg0}
  end
  def bulk_update(arg0) do
    {:BulkUpdate, arg0}
  end
  def user_online(arg0) do
    {:UserOnline, arg0}
  end
  def user_offline(arg0) do
    {:UserOffline, arg0}
  end
  def system_alert(arg0, arg1) do
    {:SystemAlert, arg0, arg1}
  end
end