defmodule Status do
  def success(arg0) do
    {0, arg0}
  end
  def error(arg0, arg1) do
    {1, arg0, arg1}
  end
  def processing() do
    {2}
  end
end
