defmodule HashMap do
  import Kernel, except: [to_string: 1], warn: false
  def new(entries_param) do
    struct = %{:__reflaxe_class__ => HashMap, :entries => nil}
    struct = %{struct | entries: if (Reflaxe.Elixir.HaxeFloat.eq(entries_param, nil)) do
      %{}
    else
      entries_param
    end}
    struct
  end
  def set(struct, k, v) do
    _ = %{struct | entries: Map.put(struct.entries, hash(k), %{key: k, value: v})}
  end
  def get(struct, k) do

          case Map.get(struct.entries, hash(k)) do
            nil -> nil
            %{value: value} -> value
          end

  end
  def exists(struct, k) do
    Map.has_key?(struct.entries, hash(k))
  end
  def remove(struct, k) do
    result = (
          hash = hash(k)
          {Map.delete(struct.entries, hash), Map.has_key?(struct.entries, hash)}
    )
    struct = %{struct | entries: elem(result, 0)}
    {struct, elem(result, 1)}
  end
  def keys(struct) do
    iterator_from_list((fn ->
          struct.entries
          |> Map.values()
          |> Enum.map(fn %{key: key} -> key end)
     end).())
  end
  def iterator(struct) do
    iterator_from_list((fn ->
          struct.entries
          |> Map.values()
          |> Enum.map(fn %{value: value} -> value end)
     end).())
  end
  def key_value_iterator(struct) do
    iterator_from_list((fn ->
          struct.entries
          |> Map.values()
          |> Enum.map(fn %{key: key, value: value} -> %{key: key, value: value} end)
     end).())
  end
  def copy(struct) do
    HashMap.new(struct.entries)
  end
  def to_string(struct) do

          struct.entries
          |> Map.values()
          |> Enum.map(fn %{key: key, value: value} ->
            Std.string(key) <> " => " <> Std.string(value)
          end)
          |> Enum.join(", ")
          |> then(fn body -> "{" <> body <> "}" end)

  end
  def clear(struct) do
    _ = %{struct | entries: %{}}
  end
  defp hash(key) do
    apply(Map.get(key, :__reflaxe_class__) || Map.get(key, :__struct__), :hash_code, [key])
  end
  defp iterator_from_list(values) do

          ref = make_ref()
          state_key = {HashMapIterator, ref}
          %{
            ref: ref,
            current: 0,
            has_next: fn ->
              Process.get(state_key, 0) < length(values)
            end,
            next: fn ->
              index = Process.get(state_key, 0)
              Process.put(state_key, index + 1)
              Enum.at(values, index)
            end
          }

  end
end
