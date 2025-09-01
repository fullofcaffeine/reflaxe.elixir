defmodule Container do
  def box(arg0) do
    {:Box, arg0}
  end
  def list(arg0) do
    {:List, arg0}
  end
  def empty() do
    {:Empty}
  end
end