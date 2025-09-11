defmodule PubSubMessage do
  def todo_created(arg0) do
    {0, arg0}
  end
  def todo_updated(arg0) do
    {1, arg0}
  end
  def todo_deleted(arg0) do
    {2, arg0}
  end
  def bulk_update(arg0) do
    {3, arg0}
  end
  def user_online(arg0) do
    {4, arg0}
  end
  def user_offline(arg0) do
    {5, arg0}
  end
  def system_alert(arg0, arg1) do
    {6, arg0, arg1}
  end
end