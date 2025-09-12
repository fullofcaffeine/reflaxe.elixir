defmodule Organization do
  use Ecto.Schema
  import Ecto.Changeset
  schema "organizations" do
    field(:name, :string)
    field(:domain, :string)
    field(:users, :string)
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
  
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :domain, :users, :inserted_at, :updated_at])
    |> validate_required(["name", "domain", "users", "inserted_at", "updated_at"])
  end
end