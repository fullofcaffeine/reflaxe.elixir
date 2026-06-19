defmodule Calculator do
  def new(b) do
    struct = %{:__reflaxe_class__ => Calculator, :base => nil}
    struct = %{struct | base: b}
    struct
  end
  def add(struct, x) do
    struct.base + x
  end
  def multiply(struct, x) do
    struct.base * x
  end
  def concatenate(struct, str) do
    "Base: #{Reflaxe.Elixir.HaxeFloat.to_string(struct.base)}, Input: #{str}"
  end
end
