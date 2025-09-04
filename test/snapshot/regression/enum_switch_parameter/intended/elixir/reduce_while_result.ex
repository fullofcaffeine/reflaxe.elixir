defmodule Elixir.ReduceWhileResult do
  def cont(arg0) do
    {:Cont, arg0}
  end
  def halt(arg0) do
    {:Halt, arg0}
  end
end