defmodule InvalidSchema do
  use Ecto.Schema
  import Ecto.Changeset
  schema "invalid_schemas" do
    field(:valid_field, :string)
    field(:invalid_type_field, :string)
  end
  
  def changeset(invalidschema, attrs) do
    invalidschema
    |> cast(attrs, [:validField, :invalidTypeField])
    |> validate_required(["validField", "invalidTypeField"])
  end
end