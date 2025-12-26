defmodule User do
  use Ecto.Schema
  schema "users" do
    _ = field(:name, :string)
    _ = field(:email, :string)
    _ = field(:age, :integer)
    _ = field(:active, :boolean)
  end
  
  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:name, :email, :age, :active])
    |> Ecto.Changeset.validate_required([:name, :email, :age, :active])
  end
end
