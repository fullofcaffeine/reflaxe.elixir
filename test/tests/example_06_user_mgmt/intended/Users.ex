defmodule Users do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :is_active, :boolean, default: true
    
    timestamps()
  end

  @doc """
  Creates a changeset for user creation/updates
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :is_active])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 0, less_than: 150)
    |> unique_constraint(:email)
  end
end