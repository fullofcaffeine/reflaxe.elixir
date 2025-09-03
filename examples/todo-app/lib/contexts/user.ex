defmodule User do
  use Ecto.Schema
  import Ecto.Changeset
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password_hash, :string)
    field(:confirmed_at, :naive_datetime)
    field(:last_login_at, :naive_datetime)
    field(:active, :boolean, [default: true])
    timestamps()
  end
  
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :active])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> unique_constraint(:email)
  end
end