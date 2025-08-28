defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    User struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:name, :age, :balance]

  @type t() :: %__MODULE__{
    name: String.t() | nil,
    age: integer() | nil,
    balance: float() | nil
  }

  @doc "Creates a new struct with default values"
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Log.trace("Testing complex metadata syntax", %{fileName: "MetadataTest.hx", lineNumber: 14, className: "User", methodName: "main"})
  end

end
