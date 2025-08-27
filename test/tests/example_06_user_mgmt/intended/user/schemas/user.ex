defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    User struct generated from Haxe

     * Complete user management context with Ecto integration
     * Demonstrates schemas, changesets, queries, and business logic
  """

  defstruct [:id, :name, :email, :age, :active, :inserted_at, :updated_at, :posts]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    name: String.t() | nil,
    email: String.t() | nil,
    age: integer() | nil,
    active: boolean() | nil,
    inserted_at: String.t() | nil,
    updated_at: String.t() | nil,
    posts: Array.t() | nil
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
