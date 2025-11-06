defmodule Option do
  def none() do
    {0}
  end
  def some(arg0) do
    {1, arg0}
  end
end
