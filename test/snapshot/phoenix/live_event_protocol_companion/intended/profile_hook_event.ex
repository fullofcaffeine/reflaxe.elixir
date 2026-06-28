defmodule ProfileHookEvent do
  def clipboard_copied(arg0) do
    {0, arg0}
  end
  def ping() do
    {1}
  end
  def todo_selected(arg0, arg1) do
    {2, arg0, arg1}
  end
end
