defmodule Post do
  use Ecto.Schema
  import Ecto.Changeset
  schema "posts" do
    field(:title, :string)
    field(:content, :string)
    field(:published, :boolean)
    field(:view_count, :integer)
    field(:user, :string)
    field(:user_id, :integer)
    field(:comments, :string)
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
  
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :content, :published, :view_count, :user, :user_id, :comments, :inserted_at, :updated_at])
    |> validate_required(["title", "content", "published", "view_count", "user", "user_id", "comments", "inserted_at", "updated_at"])
  end
end