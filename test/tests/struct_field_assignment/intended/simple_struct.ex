defmodule SimpleStruct do
  @moduledoc """
    SimpleStruct struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:field]

  @type t() :: %__MODULE__{
    field: String.t() | nil
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
    struct |> Map.merge(changes) |> struct(__MODULE__, _1)
  end

  # Instance functions
  @doc "Function update_field"
  @spec update_field(t(), integer()) :: nil
  def update_field(%__MODULE__{} = struct, value) do
    __MODULE__.__MODULE__.field = "test"
  end

end
