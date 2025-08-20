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
  @doc "Function add"
  @spec add(t(), T.t()) :: nil
  def add(%__MODULE__{} = struct, item) do
    struct.items ++ [item]
  end

  @doc "Function get"
  @spec get(t(), integer()) :: T.t()
  def get(%__MODULE__{} = struct, index) do
    Enum.at(struct.items, index)
  end

  @doc "Function size"
  @spec size(t()) :: integer()
  def size(%__MODULE__{} = struct) do
    struct.items.length
  end

  @doc "Function map"
  @spec map(t(), Function.t()) :: Container.t()
  def map(%__MODULE__{} = struct, fn_) do
    result = Container.new()
    _g_counter = 0
    _g_2 = struct.items
    (
      loop_helper = fn loop_fn, {g_2} ->
        if (g < g.length) do
          try do
            item = Enum.at(g, g)
    g = g + 1
    result.add(&Container.fn_/1(item))
            loop_fn.(loop_fn, {g_2})
          catch
            :break -> {g_2}
            :continue -> loop_fn.(loop_fn, {g_2})
          end
        else
          {g_2}
        end
      end
      {g_2} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    result
  end

end
