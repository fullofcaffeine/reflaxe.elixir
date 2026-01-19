defmodule BulkAction do
  def complete_all() do
    {0}
  end
  def delete_completed() do
    {1}
  end
  def set_priority(arg0) do
    {2, arg0}
  end
end
