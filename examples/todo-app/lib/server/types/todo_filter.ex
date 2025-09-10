defmodule Server.Types.TodoFilter do
  def all() do
    {0}
  end
  def active() do
    {1}
  end
  def completed() do
    {2}
  end
  def by_tag(arg0) do
    {3, arg0}
  end
  def by_priority(arg0) do
    {4, arg0}
  end
  def by_due_date(arg0) do
    {5, arg0}
  end
end