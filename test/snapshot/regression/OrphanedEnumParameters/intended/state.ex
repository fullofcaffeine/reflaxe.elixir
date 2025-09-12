defmodule State do
  def loading(arg0) do
    {0, arg0}
  end
  def processing(arg0) do
    {1, arg0}
  end
  def complete(arg0) do
    {2, arg0}
  end
  def error(arg0) do
    {3, arg0}
  end
end