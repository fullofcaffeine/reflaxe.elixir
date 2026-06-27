defmodule Example.User do
  use Ecto.Schema
  schema "users" do
    _ = field(:email, :string)
  end

  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:email])
    |> Ecto.Changeset.validate_required([:email])
  end
end
