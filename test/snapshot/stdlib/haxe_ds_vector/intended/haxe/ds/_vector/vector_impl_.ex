defmodule Vector_Impl_ do
  def _new(length, default_value) do
    items = []
    _g = 0
    g_value = length
    items = Enum.reduce(0..(g_value - 1)//1, items, fn _, items_acc -> Enum.concat(items_acc, [default_value]) end)
    VectorData.new(length, items)
  end
  def get(this1, index) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :get, [this1, index])
  end
  def set(this1, index, value) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :set, [this1, index, value])
  end
  def fill(this1, value) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :put_items, [this1, List.duplicate(value, this1.length)])
  end
  def blit(src, src_pos, dest, dest_pos, len) do
    src_data = src
    dest_data = dest
    src_items = apply(Map.get(src_data, :__reflaxe_class__) || Map.get(src_data, :__struct__), :items, [src_data])
    dest_items = apply(Map.get(dest_data, :__reflaxe_class__) || Map.get(dest_data, :__struct__), :items, [dest_data])
    apply(Map.get(dest_data, :__reflaxe_class__) || Map.get(dest_data, :__struct__), :put_items, (fn -> [dest_data,
          Enum.reduce(0..(len - 1)//1, dest_items, fn offset, acc ->
            List.replace_at(acc, dest_pos + offset, Enum.at(src_items, src_pos + offset))
          end)
    ] end).())
  end
  def to_array(this1) do
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :items, [this1])
  end
  def to_data(this1) do
    this1
  end
  def from_data(data) do
    data
  end
  def from_array_copy(array) do
    VectorData.new(length(array), array)
  end
  def copy(this1) do
    VectorData.new(this1.length, apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :items, [this1]))
  end
  def join(this1, sep) do
    Enum.map(apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :items, [this1]), fn item -> Std.string(item) end) |> Enum.join(sep)
  end
  def map(this1, f) do
    mapped = Enum.map(apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :items, [this1]), f)
    VectorData.new(this1.length, mapped)
  end
  def sort(this1, f) do
    comparator = fn left, right -> f.(left, right) < 0 end
    apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :put_items, [this1, Enum.sort(apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :items, [this1]), comparator)])
  end
  def iterator(this1) do
    snapshot = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :items, [this1])
    Type.create_instance(ArrayIterator, [snapshot])
  end
end
