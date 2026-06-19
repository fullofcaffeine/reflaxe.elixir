defmodule Child do
  def new(name_param, age_param) do
    struct = %{:__reflaxe_class__ => Child, :age => nil, :name => nil}
    struct = Map.merge(struct, Map.drop(Parent.new(name_param), [:__struct__, :__reflaxe_class__]))
    struct = %{struct | age: age_param}
    struct
  end
  def get_age(struct) do
    struct.age
  end
  def get_description(struct) do
    "#{Parent.get_description(super)}, Age: #{Reflaxe.Elixir.HaxeFloat.to_string(struct.age)}"
  end
  def get_name(struct) do
    Parent.get_name(struct)
  end
end
