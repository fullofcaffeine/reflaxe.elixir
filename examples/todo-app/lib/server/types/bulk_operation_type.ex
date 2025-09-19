defmodule Server.Types.BulkOperationType do
  def complete_all() do
    {0}
  end
  def delete_completed() do
    {1}
  end
  def set_priority(arg0) do
    {2, arg0}
  end
  def add_tag(arg0) do
    {3, arg0}
  end
  def remove_tag(arg0) do
    {4, arg0}
  end
end