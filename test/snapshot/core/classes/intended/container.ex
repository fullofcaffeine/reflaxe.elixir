defmodule Container do
  @moduledoc """
    Container struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:items]

  @type t() :: %__MODULE__{
    items: Array.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new() :: t()
  def new() do
    %__MODULE__{
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe add"
  def add(%__MODULE__{} = struct, item) do
    struct.items ++ [item]
  end

  @doc "Generated from Haxe get"
  def get(%__MODULE__{} = struct, _index) do
    Enum.at(struct.items, _index)
  end

  @doc "Generated from Haxe size"
  def size(%__MODULE__{} = struct) do
    struct.items.length
  end

  @doc "Generated from Haxe map"
  def map(%__MODULE__{} = struct, fn_) do
    result = Container.new()

    g_counter = 0

    g_array = struct.items

    (fn loop ->
      if ((g_counter < g_array.length)) do
            item = Enum.at(g_array, g_counter)
        g_counter + 1
        result.add(fn_.(item))
        loop.()
      end
    end).()

    result
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
