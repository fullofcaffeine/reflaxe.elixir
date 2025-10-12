defmodule Post do
  use Ecto.Schema
  schema "posts" do
    field(:title, :string)
    field(:content, :string)
    field(:published, :boolean)
    field(:view_count, :integer)
    field(:user, :string)
    field(:user_id, :integer)
    field(:comments, {:array, :string})
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
end
