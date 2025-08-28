defmodule Int64 do
  @moduledoc """
    Int64 struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:high, :low]

  @type t() :: %__MODULE__{
    high: Int32.t() | nil,
    low: Int32.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(Int32.t(), Int32.t()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      high: arg0,
      low: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe toString"
  def format(%__MODULE__{} = struct) do
    Int64_Impl_.to_string(struct)
  end

end
