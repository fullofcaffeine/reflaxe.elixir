defmodule Option do
  def some(arg0) do
    {0, arg0}
  end
  def none() do
    {1}
  end
end