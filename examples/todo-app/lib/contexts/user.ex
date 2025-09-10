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
  end
  
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :active, :posts])
    |> validate_required(["name", "email", "age", "active", "posts"])
  end
end