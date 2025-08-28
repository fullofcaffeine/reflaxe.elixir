defmodule ArrayTools do
  @moduledoc """
    ArrayTools module generated from Haxe

     * ArrayTools static extension for functional array methods
     *
     * Provides functional programming methods for Array<T> including:
     * - Accumulation: reduce, fold
     * - Search: find, findIndex
     * - Predicates: exists/any, all/foreach
     * - Collection ops: forEach, take, drop, flatMap
     *
     * Usage:
     *   using ArrayTools;
     *   var numbers = [1, 2, 3, 4, 5];
     *   var sum = numbers.reduce((acc, item) -> acc + item, 0);
  """

  # Static functions
  @doc "Generated from Haxe reduce"
  def reduce(array, func, initial) do
    Enum.reduce(array, initial, fn item, acc -> func.(acc, item) end)
  end

  @doc "Generated from Haxe fold"
  def fold(array, func, initial) do
    Enum.reduce(array, initial, func)
  end

  @doc "Generated from Haxe find"
  def find(array, predicate) do
    Enum.find(array, fn item -> predicate.(item) end)
  end

  @doc "Generated from Haxe findIndex"
  def find_index(array, predicate) do
    case Enum.find_index(array, fn item -> predicate.(item) end) do
          nil -> -1
          index -> index
        end
  end

  @doc "Generated from Haxe exists"
  def exists(array, predicate) do
    Enum.any?(array, fn item -> predicate.(item) end)
  end

  @doc "Generated from Haxe any"
  def any(array, predicate) do
    Enum.any?(array, predicate)
  end

  @doc "Generated from Haxe foreach"
  def foreach(array, predicate) do
    Enum.all?(array, fn item -> predicate.(item) end)
  end

  @doc "Generated from Haxe all"
  def all(array, predicate) do
    Enum.all?(array, predicate)
  end

  @doc "Generated from Haxe forEach"
  def for_each(array, action) do
    Enum.each(array, fn item -> action.(item) end)
  end

  @doc "Generated from Haxe take"
  def take(array, n) do
    Enum.take(array, n)
  end

  @doc "Generated from Haxe drop"
  def drop(array, n) do
    Enum.drop(array, n)
  end

  @doc "Generated from Haxe flatMap"
  def flat_map(array, mapper) do
    Enum.flat_map(array, fn item -> mapper.(item) end)
  end

end
