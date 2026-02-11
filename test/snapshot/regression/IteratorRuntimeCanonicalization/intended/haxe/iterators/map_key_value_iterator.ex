defmodule MapKeyValueIterator do
  def new(map) do
    struct = %{:__reflaxe_class__ => MapKeyValueIterator, :pairs => nil, :ref => nil, :current => nil}
    struct = %{struct | current: 0}
    struct = %{struct | pairs: 
            cond do
                Kernel.is_list(map) ->
                    Enum.map(map, fn
                        {key, value} -> %{key: key, value: value}
                        %{key: _key, value: _value} = pair -> pair
                        _ -> %{key: nil, value: nil}
                    end)
                Kernel.is_map(map) ->
                    Enum.map(Map.to_list(map), fn {key, value} ->
                        %{key: key, value: value}
                    end)
                true ->
                    []
            end
        }
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
