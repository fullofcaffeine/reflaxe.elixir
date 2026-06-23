defmodule UserExplicit do
  use Ecto.Schema
  schema "users_explicit" do
    _ = field(:name, :string)
    _ = field(:email, :string)
  end
  def new() do
    %{:__reflaxe_class__ => UserExplicit, :id => nil, :name => nil, :email => nil}
  end

  def changeset(userexplicit, attrs) do
    userexplicit
    |> Ecto.Changeset.cast(attrs, [:name, :email])
    |> Ecto.Changeset.validate_required([:name, :email])
  end
end
