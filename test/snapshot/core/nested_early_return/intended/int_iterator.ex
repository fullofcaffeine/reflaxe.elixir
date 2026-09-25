defmodule IntIterator do
  def new(min_param, max_param) do
    struct = %{:__reflaxe_class__ => IntIterator, :min => nil, :max => nil}
    struct = %{struct | min: min_param}
    struct = %{struct | max: max_param}
    struct
  end
  def has_next(struct) do
    struct.min < struct.max
  end
  def next(struct) do
    {_struct, _reflaxe_receiver_value_0} = {%{struct | min: struct.min + 1}, struct.min}
  end
end
