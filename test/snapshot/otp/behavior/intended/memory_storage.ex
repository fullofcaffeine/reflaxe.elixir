defmodule MemoryStorage do
  def new() do
    struct = %{:__reflaxe_class__ => MemoryStorage, :data => nil}
    struct = %{struct | data: %{}}
    struct
  end
  def init(struct, _config) do
    %{:ok => struct}
  end
  def get(struct, key) do
    this1 = struct.data
    _ = Map.get(this1, key)
  end
  def put(struct, key, value) do
    this1 = struct.data
    _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :set, [this1, key, value])
    true
  end
  def delete(struct, key) do
    this1 = struct.data
    _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :remove, [this1, key])
  end
  def list(struct) do
    this1 = struct.data
    Enum.reduce_while(Map.keys(this1), {[]}, fn k, {acc__g} ->
      try do
        acc__g = acc__g ++ [k]
        {:cont, {acc__g}}
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
