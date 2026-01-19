defmodule TestEnum do
  def created(arg0) do
    {0, arg0}
  end
  def updated(arg0, arg1) do
    {1, arg0, arg1}
  end
  def deleted() do
    {2}
  end
end
