defmodule MemoryStorage do
  @moduledoc """
    MemoryStorage struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:data]

  @type t() :: %__MODULE__{
    data: Map.t() | nil
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
  @doc "Function init"
  @spec init(t(), term()) :: t()
  def init(%__MODULE__{} = struct, config) do
    %{"ok" => struct}
  end

  @doc "Function get"
  @spec get(t(), String.t()) :: t()
  def get(%__MODULE__{} = struct, key) do
    (
          struct = struct.data
          temp_result = struct.get(key)
          temp_result
        )
  end

  @doc "Function put"
  @spec put(t(), String.t(), term()) :: boolean()
  def put(%__MODULE__{} = struct, key, value) do
    (
          struct = struct.data
          struct.set(key, value)
          true
        )
  end

  @doc "Function delete"
  @spec delete(t(), String.t()) :: boolean()
  def delete(%__MODULE__{} = struct, key) do
    (
          struct = struct.data
          temp_result = struct.remove(key)
          temp_result
        )
  end

  @doc "Function list"
  @spec list(t()) :: Array.t()
  def list(%__MODULE__{} = struct) do
    (
          g_array = []
          struct = struct.data
          temp_iterator = struct.keys()
          k = temp_iterator
          while_loop(fn -> (k.has_next()) end, fn -> (
          k = k.next()
          g ++ [k]
        ) end)
          g
        )
  end

end
