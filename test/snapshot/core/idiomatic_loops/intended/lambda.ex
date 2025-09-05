defmodule Lambda do
  def array(it) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    arr.push(acc_v)
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def list(it) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    arr.push(acc_v)
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def concat(a, b) do
    arr = []
    v = a.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    arr.push(acc_v)
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    v = b.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    arr.push(acc_v)
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def map(it, f) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    arr.push(f.(acc_v))
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def filter(it, f) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    if (f.(acc_v)), do: arr.push(acc_v)
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def fold(it, f, first) do
    acc = first
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc, v, :ok}, fn _, {acc_acc, acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    acc_acc = f.(acc_v, acc_acc)
    {:cont, {acc_acc, acc_v, acc_state}}
  else
    {:halt, {acc_acc, acc_v, acc_state}}
  end
end)
    acc
  end
  def count(it, pred) do
    n = 0
    if (pred == nil) do
      item = it.iterator()
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {item, n, :ok}, fn _, {acc_item, acc_n, acc_state} ->
  if (acc_item.hasNext()) do
    _item = acc_item.next()
    acc_n = acc_n + 1
    {:cont, {acc_item, acc_n, acc_state}}
  else
    {:halt, {acc_item, acc_n, acc_state}}
  end
end)
    else
      v = it.iterator()
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, v, :ok}, fn _, {acc_n, acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    if (pred(acc_v)) do
      acc_n = acc_n + 1
    end
    {:cont, {acc_n, acc_v, acc_state}}
  else
    {:halt, {acc_n, acc_v, acc_state}}
  end
end)
    end
    n
  end
  def exists(it, f) do
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    if (f.(acc_v)), do: true
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    false
  end
  def foreach(it, f) do
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    if (not f.(acc_v)), do: false
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    true
  end
  def find(it, f) do
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.hasNext()) do
    acc_v = acc_v.next()
    if (f.(acc_v)), do: acc_v
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    nil
  end
  def empty(it) do
    item = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {item, :ok}, fn _, {acc_item, acc_state} ->
  if (acc_item.hasNext()) do
    _item = acc_item.next()
    false
    {:cont, {acc_item, acc_state}}
  else
    {:halt, {acc_item, acc_state}}
  end
end)
    true
  end
  def index_of(it, v) do
    i = 0
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x, i, :ok}, fn _, {acc_x, acc_i, acc_state} ->
  if (acc_x.hasNext()) do
    acc_x = acc_x.next()
    if (acc_x == v), do: acc_i
    acc_i = acc_i + 1
    {:cont, {acc_x, acc_i, acc_state}}
  else
    {:halt, {acc_x, acc_i, acc_state}}
  end
end)
    -1
  end
  def has(it, v) do
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x, :ok}, fn _, {acc_x, acc_state} ->
  if (acc_x.hasNext()) do
    acc_x = acc_x.next()
    if (acc_x == v), do: true
    {:cont, {acc_x, acc_state}}
  else
    {:halt, {acc_x, acc_state}}
  end
end)
    false
  end
  def iter(it, f) do
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x, :ok}, fn _, {acc_x, acc_state} ->
  if (acc_x.hasNext()) do
    acc_x = acc_x.next()
    f.(acc_x)
    {:cont, {acc_x, acc_state}}
  else
    {:halt, {acc_x, acc_state}}
  end
end)
  end
end