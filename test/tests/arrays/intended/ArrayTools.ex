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
  @doc """
    Reduces array to single value using accumulator function
    @param array The array to reduce
    @param func Accumulator function (acc, item) -> newAcc
    @param initial Initial accumulator value
    @return Final accumulated value
  """
  @spec reduce(Array.t(), Function.t(), U.t()) :: U.t()
  def reduce(array, func, initial) do
    _g = 0
    Enum.map(array, fn initial -> item = Enum.at(array, _g)
    _g = _g + 1
    initial = func.(initial, item) end)
    initial
  end

  @doc """
    Alias for reduce - reduces array to single value
    @param array The array to fold
    @param func Accumulator function (acc, item) -> newAcc
    @param initial Initial accumulator value
    @return Final accumulated value
  """
  @spec fold(Array.t(), Function.t(), U.t()) :: U.t()
  def fold(array, func, initial) do
    Enum.reduce(array, initial, func)
  end

  @doc """
    Finds first element matching predicate
    @param array The array to search
    @param predicate Test function
    @return First matching element or null
  """
  @spec find(Array.t(), Function.t()) :: Null.t()
  def find(array, predicate) do
    _g = 0
    Enum.find(array, fn item -> (predicate.(item)) end)
    nil
  end

  @doc """
    Finds index of first element matching predicate
    @param array The array to search
    @param predicate Test function
    @return Index of first match or -1
  """
  @spec find_index(Array.t(), Function.t()) :: integer()
  def find_index(array, predicate) do
    _g = 0
    _g = length(array)
    (
      try do
        loop_fn = fn ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
    if (predicate.(Enum.at(array, i))), do: i, else: nil
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    -1
  end

  @doc """
    Tests if any element matches predicate
    @param array The array to test
    @param predicate Test function
    @return True if any element matches
  """
  @spec exists(Array.t(), Function.t()) :: boolean()
  def exists(array, predicate) do
    _g = 0
    Enum.find(array, fn item -> (predicate.(item)) end)
    false
  end

  @doc """
    Alias for exists - tests if any element matches

  """
  @spec any(Array.t(), Function.t()) :: boolean()
  def any(array, predicate) do
    Enum.any?(array, predicate)
  end

  @doc """
    Tests if all elements match predicate
    @param array The array to test
    @param predicate Test function
    @return True if all elements match
  """
  @spec foreach(Array.t(), Function.t()) :: boolean()
  def foreach(array, predicate) do
    _g = 0
    Enum.find(array, fn item -> (!predicate.(item)) end)
    true
  end

  @doc """
    Alias for foreach - tests if all elements match

  """
  @spec all(Array.t(), Function.t()) :: boolean()
  def all(array, predicate) do
    Enum.all?(array, predicate)
  end

  @doc """
    Executes function for each element (side effects)
    @param array The array to iterate
    @param action Function to execute for each element
  """
  @spec for_each(Array.t(), Function.t()) :: nil
  def for_each(array, action) do
    _g = 0
    Enum.map(array, fn item -> item = Enum.at(array, _g)
    _g = _g + 1
    action.(item) end)
  end

  @doc """
    Returns first n elements
    @param array The source array
    @param n Number of elements to take
    @return New array with first n elements
  """
  @spec take(Array.t(), integer()) :: Array.t()
  def take(array, n) do
    array.slice(0, n)
  end

  @doc """
    Skips first n elements
    @param array The source array
    @param n Number of elements to skip
    @return New array without first n elements
  """
  @spec drop(Array.t(), integer()) :: Array.t()
  def drop(array, n) do
    array.slice(n)
  end

  @doc """
    Maps and flattens the result
    @param array The source array
    @param mapper Function that returns array for each element
    @return Flattened result array
  """
  @spec flat_map(Array.t(), Function.t()) :: Array.t()
  def flat_map(array, mapper) do
    result = []
    _g = 0
    Enum.map(array, fn item -> item = Enum.at(array, _g)
    _g = _g + 1
    mapped = mapper.(item)
    _g = 0
    Enum.map(mapped, fn item -> mapped_item = Enum.at(mapped, _g)
    _g = _g + 1
    result ++ [mapped_item] end) end)
    result
  end

end
