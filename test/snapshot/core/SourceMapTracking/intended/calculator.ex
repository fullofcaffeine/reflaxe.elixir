defmodule Calculator do
  def new() do
    %{:value => 0, :value => 0}
  end
  def add(struct, n) do
    value = struct.value + n
  end
  def multiply(struct, factor) do
    value = struct.value * factor
  end
  def get_value(struct) do
    struct.value
  end
end