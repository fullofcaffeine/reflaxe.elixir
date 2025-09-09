defmodule Vehicle do
  @speed nil
  def accelerate(struct) do
    throw("Abstract method")
  end
end