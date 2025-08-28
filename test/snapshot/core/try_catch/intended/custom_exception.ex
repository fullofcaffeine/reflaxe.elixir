defmodule CustomException do
  @moduledoc """
    CustomException struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:code]

  @type t() :: %__MODULE__{
    code: integer() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(String.t(), integer()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      code: arg0
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

end
