defmodule ConstructorTest.User do
  use Ecto.Schema
  import Ecto.Changeset
  schema "users" do
    field(:name, :string)
    field(:email, :string)
  end
  
  def changeset(constructortest.user, attrs) do
    constructortest.user
    |> cast(attrs, [:name, :email])
    |> validate_required(["name", "email"])
  end
end