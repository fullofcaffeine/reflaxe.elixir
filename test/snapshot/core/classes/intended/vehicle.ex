defmodule Vehicle do
  def accelerate(_struct) do
    throw("Abstract method")
  end
end
