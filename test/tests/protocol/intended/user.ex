defmodule User do
  @moduledoc """
    User struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:name, :age]

  @type t() :: %__MODULE__{
    name: String.t() | nil,
    age: integer() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(String.t(), integer()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      name: arg0,
      age: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

end
