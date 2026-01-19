defmodule Child do
  def new(name, age_param) do
    struct = %{:age => nil}
    struct = Map.merge(struct, Parent.new(name))
    struct = %{struct | age: age_param}
    struct
  end
  def get_age(struct) do
    struct.age
  end
  def get_description(struct) do
    "#{Parent.get_description(super)}, Age: #{Kernel.to_string(struct.age)}"
  end
end
