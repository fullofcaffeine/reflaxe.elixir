defmodule Label do
  def new(name_param) do
    struct = %{:__reflaxe_class__ => Label, :name => nil}
    struct = %{struct | name: name_param}
    struct
  end
end
