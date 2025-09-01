defmodule Vehicle do
  def new() do
    %{:speed => 0}
  end
  def accelerate(struct) do
    throw("Abstract method")
  end
end