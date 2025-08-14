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
