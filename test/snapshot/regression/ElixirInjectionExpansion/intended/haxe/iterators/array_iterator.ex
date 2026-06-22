defmodule ArrayIterator do
  def new(array_param) do
    struct = %{:__reflaxe_class__ => ArrayIterator, :array => nil, :ref => nil, :current => nil}
    struct = %{struct | current: 0}
    struct = %{struct | array: array_param}
    struct = %{struct | ref: make_ref()}
    struct
  end
  defp state_key(struct) do
    {__MODULE__, struct.ref}
  end
  defp current_index(struct) do
    Process.get(state_key(struct), struct.current)
  end
  def has_next(struct) do
    current_index(struct) < length(struct.array)
    item
  end
  def next(struct) do
    index = current_index(struct)
    Process.put(state_key(struct), index + 1)
    Enum.at(struct.array, index)
    item
  end
end
