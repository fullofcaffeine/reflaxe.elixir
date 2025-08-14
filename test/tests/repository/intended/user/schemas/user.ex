defmodule User do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: users
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "users" do
    field :name, :string, null: false
    field :email, :string, null: false
    field :age, :integer
    field :active, :boolean, default: true
    field :updated_at, :string
  end

  @doc """
  Changeset function for User schema
  """
  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:name, :email, :age, :active, :updated_at]
  end

  defp required_fields do
    [:name, :email]
  end

end
