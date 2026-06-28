defmodule Elixir.ReduceWhileResult do
  def cont(arg0) do
    {0, arg0}
  end
  def halt(arg0) do
    {1, arg0}
  end
end
