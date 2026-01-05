defmodule Status do
  def ok() do
    {0}
  end
  def error(arg0) do
    {1, arg0}
  end
  def custom(arg0) do
    {2, arg0}
  end
end
