defmodule Vehicle do
  def new() do
    %{:speed => 0}
  end
  def accelerate(_struct) do
    throw("Abstract method")
  end
end