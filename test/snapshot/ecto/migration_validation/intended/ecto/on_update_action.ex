defmodule Ecto.OnUpdateAction do
  def restrict() do
    {0}
  end
  def cascade() do
    {1}
  end
  def set_null() do
    {2}
  end
  def no_action() do
    {3}
  end
end
