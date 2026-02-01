defmodule Map_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def set(this1, key, value) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :set, [this1, key, value])
  end
  def get(this1, key) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :get, [this1, key])
  end
  def exists(this1, key) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :exists, [this1, key])
  end
  def remove(this1, key) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :remove, [this1, key])
  end
  def keys(this1) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :keys, [this1])
  end
  def iterator(this1) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :iterator, [this1])
  end
  def key_value_iterator(this1) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :key_value_iterator, [this1])
  end
  def copy(this1) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :copy, [this1])
  end
  def to_string(this1) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :to_string, [this1])
  end
  def clear(this1) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :clear, [this1])
  end
  def array_write(this1, k, v) do
    _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :set, [this1, k, v])
    v
  end
end
