defmodule SpecialChild do
  def new(name_param, age_param) do
    struct = %{:__reflaxe_class__ => SpecialChild, :age => nil, :name => nil}
    struct = Map.merge(struct, Map.drop(Child.new(name_param, age_param), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def get_description(_struct) do
    "Special #{Child.get_description(super)}"
  end
  def get_age(struct) do
    Child.get_age(struct)
  end
end
