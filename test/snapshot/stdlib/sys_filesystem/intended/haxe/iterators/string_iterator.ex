defmodule StringIterator do
  def new(s_param) do
    struct = %{:__reflaxe_class__ => StringIterator, :s => nil, :ref => nil, :offset => nil}
    struct = %{struct | offset: 0}
    struct = %{struct | s: s_param}
    struct = %{struct | ref: make_ref()}
    struct
  end
  defp state_key(struct) do
    {__MODULE__, struct.ref}
  end
  defp current_offset(struct) do
    Process.get(state_key(struct), struct.offset)
  end
  def has_next(struct) do
    String.at(struct.s, current_offset(struct)) != nil
  end
  def next(struct) do
    index = current_offset(struct)
    Process.put(state_key(struct), index + 1)
    Enum.at(String.to_charlist(struct.s), index)
  end
end
