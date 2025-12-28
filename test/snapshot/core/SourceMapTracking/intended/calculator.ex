defmodule Calculator do
  def new() do
    struct = %{:value => nil}
    struct = %{struct | value: 0}
    struct = %{struct | value: 0}
    struct
  end
  def add(struct, n) do
    struct = %{struct | value: struct.value + n}
  end
  def multiply(struct, factor) do
    struct = %{struct | value: struct.value * factor}
  end
  def get_value(struct) do
    struct.value
  end
end
