defmodule Comment do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: comments
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "comments" do
    field :body, :string
    belongs_to :post, Post
    field :post_id, :integer
    belongs_to :user, User
    field :user_id, :integer
    field :updated_at, :string
  end

  @doc """
  Changeset function for Comment schema
  """
  def changeset(%Comment{} = comment, attrs \\ %{}) do
    comment
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:id, :body, :post_id, :user_id, :updated_at]
  end

  defp required_fields do
    []
  end

end
