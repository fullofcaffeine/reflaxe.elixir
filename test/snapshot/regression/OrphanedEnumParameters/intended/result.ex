defmodule Result do
  def success(arg0, arg1) do
    {0, arg0, arg1}
  end
  def warning(arg0) do
    {1, arg0}
  end
  def error(arg0, arg1) do
    {2, arg0, arg1}
  end
  def pending() do
    {3}
  end
end
