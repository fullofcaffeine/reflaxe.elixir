defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean, default: true

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :active])
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
  end
end