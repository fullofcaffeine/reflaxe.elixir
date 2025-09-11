defmodule Status do
  def idle() do
    {0}
  end
  def working(arg0) do
    {1, arg0}
  end
  def completed(arg0, arg1) do
    {2, arg0, arg1}
  end
  def failed(arg0, arg1) do
    {3, arg0, arg1}
  end
end