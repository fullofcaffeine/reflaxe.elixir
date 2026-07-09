defmodule MapKeyValueIterator do
  def new(map) do
    struct = %{:__reflaxe_class__ => MapKeyValueIterator, :pairs => nil, :ref => nil, :has_next => nil, :next => nil, :current => nil}
    struct = %{struct | current: 0}
    gthis = struct
    struct = %{struct | pairs: Reflaxe.Elixir.IMap.unwrap(map)}
    struct = %{struct | ref: make_ref()}
    struct = %{struct | has_next: fn -> apply(Map.get(gthis, :__reflaxe_class__) || Map.get(gthis, :__struct__), :has_next, [gthis]) end}
    struct = %{struct | next: fn -> apply(Map.get(gthis, :__reflaxe_class__) || Map.get(gthis, :__struct__), :next, [gthis]) end}
    struct
  end
  defp state_key(struct) do
    {__MODULE__, struct.ref}
  end
  defp current_index(struct) do
    Process.get(state_key(struct), struct.current)
  end
  def has_next(struct) do
    current_index(struct) < length(struct.pairs)
  end
  def next(struct) do

                index = current_index(struct)
                Process.put(state_key(struct), index + 1)
                case Enum.at(struct.pairs, index) do
                    %{key: key, value: value} -> %{key: key, value: value}
                    {key, value} -> %{key: key, value: value}
                    _ -> %{key: nil, value: nil}
                end

  end
end
