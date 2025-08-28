defmodule Vehicle do
  @moduledoc """
    Vehicle struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [speed: 0]

  @type t() :: %__MODULE__{
    speed: float()
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
  @doc "Generated from Haxe accelerate"
  def accelerate(%__MODULE__{} = struct) do
    raise "Abstract method"
  end

end
