defmodule TestClass do
  def new(name_param) do
    struct = %{:__reflaxe_class__ => TestClass, :name => nil}
    struct = %{struct | name: name_param}
    struct
  end
  def do_something(_struct) do
    nil
  end
end
