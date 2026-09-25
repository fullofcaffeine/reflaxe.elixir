defmodule ArrayKeyValueIterator do
  def new(array_param) do
    struct = %{:__reflaxe_class__ => ArrayKeyValueIterator, :array => nil, :ref => nil}
    struct = %{struct | array: array_param}
    struct = %{struct | ref: make_ref()}
    struct
  end
end
