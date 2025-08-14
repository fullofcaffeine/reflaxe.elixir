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
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean
    has_many :posts, Post
    belongs_to :organization, Organization
    field :organization_id, :integer
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
    [:id, :name, :email, :age, :active, :organization_id, :updated_at]
  end

  defp required_fields do
    []
  end

end
