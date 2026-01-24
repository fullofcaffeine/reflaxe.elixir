defmodule SpecialChild do
  def new(name, age) do
    struct = %{:__reflaxe_class__ => SpecialChild}
    struct = Map.merge(struct, Map.delete(Child.new(name, age), :__struct__))
    struct
  end
  def get_description(_) do
    "Special #{Child.get_description(super)}"
  end
  def get_age(struct) do
    Child.get_age(struct)
  end
end
