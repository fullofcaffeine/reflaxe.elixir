defmodule Organization do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: organizations
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "organizations" do
    field :name, :string
    field :domain, :string
    has_many :users, User
    field :updated_at, :string
  end

  @doc """
  Changeset function for Organization schema
  """
  def changeset(%Organization{} = organization, attrs \\ %{}) do
    organization
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:id, :name, :domain, :updated_at]
  end

  defp required_fields do
    []
  end

end
