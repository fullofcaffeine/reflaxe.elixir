defmodule Status do
  def loading() do
    {0}
  end
  def success(arg0) do
    {1, arg0}
  end
  def failure(arg0, arg1) do
    {2, arg0, arg1}
  end
end
