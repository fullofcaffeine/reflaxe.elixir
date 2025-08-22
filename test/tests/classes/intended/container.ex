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
  @spec add(t(), T.t()) :: t()
  def add(%__MODULE__{} = struct, item) do
    struct.items = struct.items.push(item)
    struct
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
    (
          result = Container.new()
          g_counter = 0
          g = struct.items
          while_loop(fn -> ((g < g.length)) end, fn -> (
          item = Enum.at(g, g)
          g + 1
          result.add(fn_.(item))
        ) end)
          result
        )
  end

end
