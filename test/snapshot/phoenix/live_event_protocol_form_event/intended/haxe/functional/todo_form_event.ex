defmodule TodoFormEvent do
  def create_todo(arg0) do
    {0, arg0}
  end
  def update_form(arg0) do
    {1, arg0}
  end
  def clear_completed() do
    {2}
  end
end
