defmodule ArrayTools do
  def reduce(array, func, initial) do
    Enum.reduce(array, initial, fn item, acc -> func.(acc, item) end)
  end
  def fold(array, func, initial) do
    reduce(array, func, initial)
  end
  def find(array, predicate) do
    Enum.find(array, fn item -> predicate.(item) end)
  end
  def find_index(array, predicate) do
    case Enum.find_index(array, fn item -> predicate.(item) end) do
      nil -> -1
      index -> index
    end
  end
  def exists(array, predicate) do
    Enum.any?(array, fn item -> predicate.(item) end)
  end
  def any(array, predicate) do
    exists(array, predicate)
  end
  def foreach(array, predicate) do
    Enum.all?(array, fn item -> predicate.(item) end)
  end
  def all(array, predicate) do
    foreach(array, predicate)
  end
  def for_each(array, action) do
    Enum.each(array, fn item -> action.(item) end)
  end
  def take(array, n) do
    Enum.take(array, n)
  end
  def drop(array, n) do
    Enum.drop(array, n)
  end
  def flat_map(array, mapper) do
    Enum.flat_map(array, fn item -> mapper.(item) end)
  end
end
