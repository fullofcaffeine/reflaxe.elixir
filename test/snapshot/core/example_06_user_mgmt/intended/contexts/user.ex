defmodule User do
  use Ecto.Schema
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:age, :integer)
    field(:active, :boolean)
  end
  
  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:name, :email, :age, :active])
    |> Ecto.Changeset.validate_required([:name, :email, :age, :active])
  end
end
