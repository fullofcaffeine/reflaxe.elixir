defmodule Message do
  def created(arg0) do
    {0, arg0}
  end
  def updated(arg0, arg1) do
    {1, arg0, arg1}
  end
  def deleted(arg0) do
    {2, arg0}
  end
  def empty() do
    {3}
  end
end