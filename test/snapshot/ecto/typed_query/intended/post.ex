defmodule Post do
  use Ecto.Schema
  import Ecto.Changeset
  schema "posts" do
    field(:title, :string)
    field(:content, :string)
    field(:user_id, :integer)
    field(:created_at, :string)
    field(:published_at, :string)
  end
end