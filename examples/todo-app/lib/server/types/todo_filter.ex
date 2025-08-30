defmodule TodoFilter do
  def all() do
    {:All}
  end
  def active() do
    {:Active}
  end
  def completed() do
    {:Completed}
  end
  def by_tag(arg0) do
    {:ByTag, arg0}
  end
  def by_priority(arg0) do
    {:ByPriority, arg0}
  end
  def by_due_date(arg0) do
    {:ByDueDate, arg0}
  end
end