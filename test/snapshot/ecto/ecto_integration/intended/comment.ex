defmodule Comment do
  use Ecto.Schema
  import Ecto.Changeset
  schema "comments" do
    field(:body, :string)
    field(:post, :string)
    field(:post_id, :integer)
    field(:user, :string)
    field(:user_id, :integer)
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
  
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :post, :post_id, :user, :user_id, :inserted_at, :updated_at])
    |> validate_required(["body", "post", "post_id", "user", "user_id", "inserted_at", "updated_at"])
  end
end