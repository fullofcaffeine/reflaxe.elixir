defmodule Vehicle do
  def new() do
    struct = %{:speed => nil}
    struct = %{struct | speed: 0}
    struct
  end
  def accelerate(_) do
    throw("Abstract method")
  end
end
