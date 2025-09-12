defmodule User do
  use Ecto.Schema
  import Ecto.Changeset
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:age, :integer)
    field(:active, :boolean)
    field(:posts, :string)
    field(:organization, :string)
    field(:organization_id, :integer)
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
  
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :active, :posts, :organization, :organization_id, :inserted_at, :updated_at])
    |> validate_required(["name", "email", "age", "active", "posts", "organization", "organization_id", "inserted_at", "updated_at"])
  end
end