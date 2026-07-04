defmodule Haxe.Ds.List do
  import Kernel, except: [to_string: 1], warn: false
  def new() do
    struct = %{:__reflaxe_class__ => Haxe.Ds.List, :items => nil, :length => nil}
    struct = %{struct | items: []}
    struct = %{struct | length: 0}
    struct
  end
  def add(struct, item) do
    struct = %{struct | items: struct.items ++ [item]}
    struct = %{struct | length: struct.length + 1}
    struct
  end
  def push(struct, item) do
    struct = %{struct | items: [item] ++ struct.items}
    struct = %{struct | length: struct.length + 1}
    struct
  end
  def first(struct) do
    if (struct.length == 0) do
      nil
    else
      Enum.at(struct.items, 0)
    end
  end
  def last(struct) do
    if (struct.length == 0) do
      nil
    else
      Enum.at(struct.items, (struct.length - 1))
    end
  end
  def pop(struct) do
    result = nil
    {result, struct} = if (struct.length > 0) do
      result = Enum.at(struct.items, 0)
      updated = []
      index = 0
      _g = 0
      g_value = struct.items
      {updated, _index} = Enum.reduce(g_value, {updated, index}, fn item, {updated_acc, index_acc} ->
        updated_acc = if (index_acc > 0), do: updated_acc ++ [item], else: updated_acc
        index_acc = index_acc + 1
        {updated_acc, index_acc}
      end)
      struct = %{struct | items: updated}
      struct = %{struct | length: (struct.length - 1)}
      {result, struct}
    else
      {result, struct}
    end
    {struct, result}
  end
  def is_empty(struct) do
    struct.length == 0
  end
  def clear(struct) do
    struct = %{struct | items: []}
    struct = %{struct | length: 0}
    struct
  end
  def remove(struct, v) do
    updated = []
    removed = false
    _g = 0
    g_value = struct.items
    {updated, removed} = Enum.reduce(g_value, {updated, removed}, fn item, {updated_acc, removed_acc} ->
      if (not removed_acc and item == v) do
        removed_acc = true
        {updated_acc, removed_acc}
      else
        updated_acc = updated_acc ++ [item]
        {updated_acc, removed_acc}
      end
    end)
    struct = if (removed) do
      struct = %{struct | items: updated}
      %{struct | length: (struct.length - 1)}
    else
      struct
    end
    {struct, removed}
  end
  def iterator(struct) do
    Type.create_instance(ArrayIterator, [struct.items])
  end
  def key_value_iterator(struct) do
    Type.create_instance(ArrayKeyValueIterator, [struct.items])
  end
  def to_string(struct) do
    "{#{Enum.join(struct.items, ", ")}}"
  end
  def join(struct, sep) do
    Enum.join((fn -> struct.items end).(), sep)
  end
  def filter(struct, f) do
    result = Haxe.Ds.List.new()
    _g = 0
    g_value = struct.items
    result = Enum.reduce(g_value, result, fn item, result_acc ->
      if (f.(item)) do
        result_acc = apply(Map.get(result_acc, :__reflaxe_class__) || Map.get(result_acc, :__struct__), :add, [result_acc, item])
        result_acc
      else
        result_acc
      end
    end)
    result
  end
  def map(struct, f) do
    result = Haxe.Ds.List.new()
    _g = 0
    g_value = struct.items
    result = Enum.reduce(g_value, result, fn item, result_acc -> apply(Map.get(result_acc, :__reflaxe_class__) || Map.get(result_acc, :__struct__), :add, [result_acc, f.(item)]) end)
    result
  end
end
