defmodule SpecialChild do
  def new(name, age) do
    struct = %{}
    struct = Map.merge(struct, Child.new(name, age))
    struct
  end
  def get_description(_) do
    "Special #{Child.get_description(super)}"
  end
end
