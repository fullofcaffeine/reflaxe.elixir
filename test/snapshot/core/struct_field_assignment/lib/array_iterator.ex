defmodule ArrayIterator do
  @moduledoc """
  Runtime support module for haxe.iterators.ArrayIterator
  
  This module provides the actual Elixir implementation for ArrayIterator.
  Handles the immutability requirement by properly returning updated state.
  """
  
  @doc """
  Creates a new iterator with initial position at 0.
  """
  def new(array) do
    %{current: 0, array: array}
  end
  
  @doc """
  Checks if there are more elements to iterate.
  """
  def has_next(iterator) do
    iterator.current < length(iterator.array)
  end
  
  @doc """
  Returns the next element without advancing (for peek operations).
  """
  def next(iterator) do
    Enum.at(iterator.array, iterator.current)
  end
  
  @doc """
  Returns the next element AND the updated iterator.
  This is the proper immutable pattern for Elixir.
  """
  def next_with_state(iterator) do
    value = Enum.at(iterator.array, iterator.current)
    new_iterator = %{iterator | current: iterator.current + 1}
    {value, new_iterator}
  end
end