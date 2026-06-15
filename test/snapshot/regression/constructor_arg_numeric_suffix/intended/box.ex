defmodule Box do
  def new(value_param) do
    struct = %{:__reflaxe_class__ => Box, :value => nil}
    struct = %{struct | value: value_param}
    struct
  end
end
