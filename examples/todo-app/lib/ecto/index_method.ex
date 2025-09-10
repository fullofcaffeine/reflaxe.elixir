defmodule Ecto.IndexMethod do
  def b_tree() do
    {0}
  end
  def hash() do
    {1}
  end
  def gin() do
    {2}
  end
  def gist() do
    {3}
  end
  def brin() do
    {4}
  end
end