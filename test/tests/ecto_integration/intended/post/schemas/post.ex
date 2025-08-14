defmodule Post do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: posts
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "posts" do
    field :title, :string
    field :content, :string
    field :published, :boolean
    field :view_count, :integer
    belongs_to :user, User
    field :user_id, :integer
    has_many :comments, Comment
    field :updated_at, :string
  end

  @doc """
  Changeset function for Post schema
  """
  def changeset(%Post{} = post, attrs \\ %{}) do
    post
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:id, :title, :content, :published, :view_count, :user_id, :updated_at]
  end

  defp required_fields do
    []
  end

end
