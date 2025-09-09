defmodule Vehicle do
  @speed nil
  def accelerate(_struct) do
    throw("Abstract method")
  end
end