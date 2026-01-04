defmodule MemoryStorage do
  def new() do
    struct = %{:data => nil}
    struct = %{struct | data: %{}}
    struct
  end
  def init(struct, _) do
    %{:ok => struct}
  end
  def get(struct, key) do
    this1 = struct.data
    _ = Map.get(this1, key)
  end
  def put(struct, key, value) do
    this1 = struct.data
    _ = Map.put(this1, key, value)
    true
  end
  def delete(struct, key) do
    this1 = struct.data
    _ = StringMap.remove(this1, key)
  end
  def list(struct) do
    this1 = struct.data
    k = _ = Map.keys(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[]}, fn _, {acc__g} ->
      try do
        if (k.has_next.()) do
          k = k.next.()
          acc__g = acc__g ++ [k]
          {:cont, {acc__g}}
        else
          {:halt, {acc__g}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc__g}}
        :throw, :continue ->
          {:cont, {acc__g}}
      end
    end)
    []
  end
end
