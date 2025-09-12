defmodule Container do
  def box(arg0) do
    {0, arg0}
  end
  def list(arg0) do
    {1, arg0}
  end
  def empty() do
    {2}
  end
end