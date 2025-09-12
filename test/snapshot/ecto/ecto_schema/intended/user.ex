defmodule User do
  use Ecto.Schema
  import Ecto.Changeset
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:age, :integer)
    field(:active, :boolean)
    field(:inserted_at, :string)
    field(:updated_at, :string)
    field(:posts, :string)
    field(:organization, :string)
    field(:organization_id, :integer)
  end
  
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :active, :inserted_at, :updated_at, :posts, :organization, :organization_id])
    |> validate_required(["name", "email", "age", "active", "inserted_at", "updated_at", "posts", "organization", "organization_id"])
  end
end