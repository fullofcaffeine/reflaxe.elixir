defmodule Status do
  def active(arg0) do
    {0, arg0}
  end
  def inactive() do
    {1}
  end
  def suspended(arg0) do
    {2, arg0}
  end
end
