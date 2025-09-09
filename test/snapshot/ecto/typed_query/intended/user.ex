defmodule User do
  use Ecto.Schema
  import Ecto.Changeset
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:active, :boolean)
    field(:role, :string)
    field(:age, :integer)
    field(:created_at, :string)
  end
  
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :active])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> unique_constraint(:email)
  end
end