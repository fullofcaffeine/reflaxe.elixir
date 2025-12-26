defmodule InvalidSchema do
  use Ecto.Schema
  schema "items" do
    _ = field(:valid_field, :string)
    _ = field(:invalid_type_field, :string)
  end
  
  def changeset(invalidschema, attrs) do
    invalidschema
    |> Ecto.Changeset.cast(attrs, [:valid_field, :invalid_type_field])
    |> Ecto.Changeset.validate_required([:valid_field, :invalid_type_field])
  end
end
