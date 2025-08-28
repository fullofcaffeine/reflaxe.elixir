defmodule InvalidSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    InvalidSchema struct generated from Haxe

     * Test for Ecto error reporting validation
     * This test intentionally contains errors to validate error messages
  """

  defstruct [:valid_field, :invalid_type_field]

  @type t() :: %__MODULE__{
    valid_field: String.t() | nil,
    invalid_type_field: String.t() | nil
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

end
