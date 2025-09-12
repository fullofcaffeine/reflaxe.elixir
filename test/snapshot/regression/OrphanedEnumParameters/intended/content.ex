defmodule Content do
  def text(arg0) do
    {0, arg0}
  end
  def number(arg0) do
    {1, arg0}
  end
  def empty() do
    {2}
  end
end