defmodule Comment do
  use Ecto.Schema
  schema "comments" do
    field(:body, :string)
    field(:post, :string)
    field(:post_id, :integer)
    field(:user, :string)
    field(:user_id, :integer)
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
end
