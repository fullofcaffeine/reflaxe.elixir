defmodule Elixir.Types.InitResult do
  def ok(arg0) do
    {0, arg0}
  end
  def ok_timeout(arg0, arg1) do
    {1, arg0, arg1}
  end
  def ok_hibernate(arg0) do
    {2, arg0}
  end
  def ok_continue(arg0, arg1) do
    {3, arg0, arg1}
  end
  def stop(arg0) do
    {4, arg0}
  end
  def ignore() do
    {5}
  end
end