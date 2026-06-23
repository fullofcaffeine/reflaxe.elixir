defmodule PhoenixHxTodo.User do
  use Ecto.Schema
  schema "users" do
    _ = field(:name, :string)
    _ = field(:email, :string)
    _ = timestamps()
  end
  def new() do
    %{:__reflaxe_class__ => PhoenixHxTodo.User, :id => nil, :name => nil, :email => nil}
  end
  def display_name(user) do
    if (not Kernel.is_nil(user.name) and user.name != ""), do: user.name, else: user.email
  end

  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:name, :email])
    |> Ecto.Changeset.validate_required([:name, :email])
  end
end
