defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    User struct generated from Haxe

     * Basic Ecto Schema test case
     * Tests @:schema annotation compilation
  """

  defstruct [:id, :name, :email, :age, active: true, :inserted_at, :updated_at, :posts, :organization, :organization_id]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    name: String.t() | nil,
    email: String.t() | nil,
    age: integer() | nil,
    active: boolean(),
    inserted_at: term() | nil,
    updated_at: term() | nil,
    posts: Array.t() | nil,
    organization: term() | nil,
    organization_id: integer() | nil
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

end
