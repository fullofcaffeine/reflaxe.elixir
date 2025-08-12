defmodule InvalidSchema do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: invalid_schemas
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "invalid_schemas" do
    field :valid_field, :string, default: "test"
    field :invalid_type_field, :invalid_type
  end

  @doc """
  Changeset function for InvalidSchema schema
  """
  def changeset(%InvalidSchema{} = invalid_schema, attrs \\ %{}) do
    invalid_schema
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:valid_field, :invalid_type_field]
  end

  defp required_fields do
    []
  end

end


defmodule InvalidChangeset do
  @moduledoc """
  Generated changeset for DefaultSchema schema
  
  Provides validation and casting for DefaultSchema data structures
  following Ecto changeset patterns with compile-time type safety.
  """
  
  import Ecto.Changeset
  alias DefaultSchema
  
  @doc """
  Primary changeset function with comprehensive validation
  """
  def changeset(%DefaultSchema{} = struct, attrs) do
    struct
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
  end
end

defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    Log.trace("Ecto error validation test", %{fileName: "Main.hx", lineNumber: 27, className: "Main", methodName: "main"})
  end

end
