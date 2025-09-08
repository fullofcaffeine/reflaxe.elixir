defmodule server.types.BulkOperationType do
  def complete_all() do
    {:CompleteAll}
  end
  def delete_completed() do
    {:DeleteCompleted}
  end
  def set_priority(arg0) do
    {:SetPriority, arg0}
  end
  def add_tag(arg0) do
    {:AddTag, arg0}
  end
  def remove_tag(arg0) do
    {:RemoveTag, arg0}
  end
end