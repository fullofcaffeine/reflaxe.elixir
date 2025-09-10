defmodule Phoenix.ChangesetAction do
  def insert() do
    {0}
  end
  def update() do
    {1}
  end
  def delete() do
    {2}
  end
  def replace() do
    {3}
  end
  def ignore() do
    {4}
  end
end