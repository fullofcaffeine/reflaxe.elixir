defmodule ValidationState do
  def valid() do
    {0}
  end
  def invalid(arg0) do
    {1, arg0}
  end
  def pending(arg0) do
    {2, arg0}
  end
end
