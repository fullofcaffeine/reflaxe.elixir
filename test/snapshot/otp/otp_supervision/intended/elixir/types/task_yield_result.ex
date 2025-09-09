defmodule elixir.types.TaskYieldResult do
  def ok(arg0) do
    {:Ok, arg0}
  end
  def exit(arg0) do
    {:Exit, arg0}
  end
end