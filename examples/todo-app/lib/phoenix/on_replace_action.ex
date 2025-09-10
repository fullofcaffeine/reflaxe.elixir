defmodule Phoenix.OnReplaceAction do
  def raise() do
    {0}
  end
  def mark_as_invalid() do
    {1}
  end
  def nilify() do
    {2}
  end
  def delete() do
    {3}
  end
  def update() do
    {4}
  end
end