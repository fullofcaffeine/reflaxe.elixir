defmodule Phoenix.OnDeleteAction do
  def nothing() do
    {0}
  end
  def restrict() do
    {1}
  end
  def delete_all() do
    {2}
  end
  def nilify_all() do
    {3}
  end
end
