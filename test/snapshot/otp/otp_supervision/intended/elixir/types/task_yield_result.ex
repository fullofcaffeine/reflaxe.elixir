defmodule Elixir.Types.TaskYieldResult do
  def ok(arg0) do
    {0, arg0}
  end
  def exit(arg0) do
    {1, arg0}
  end
end
