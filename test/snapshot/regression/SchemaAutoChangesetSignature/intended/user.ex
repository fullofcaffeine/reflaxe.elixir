defmodule User do
  use Ecto.Schema
  schema "users" do
    _ = field(:name, :string)
    _ = field(:email, :string)
  end
  def new() do
    %{:__reflaxe_class__ => User, :id => nil, :name => nil, :email => nil}
  end

  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:name, :email])
    |> Ecto.Changeset.validate_required([:name, :email])
  end
end
