defmodule Child do
  def new(name, age_param) do
    struct = %{:__reflaxe_class__ => Child, :age => nil}
    struct = Map.merge(struct, Map.delete(Parent.new(name), :__struct__))
    struct = %{struct | age: age_param}
    struct
  end
  def get_age(struct) do
    struct.age
  end
  def get_description(struct) do
    "#{Parent.get_description(super)}, Age: #{Kernel.to_string(struct.age)}"
  end
  def get_name(struct) do
    Parent.get_name(struct)
  end
end
