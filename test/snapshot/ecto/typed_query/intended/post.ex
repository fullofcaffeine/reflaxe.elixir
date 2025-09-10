defmodule Post do
  use Ecto.Schema
  import Ecto.Changeset
  schema "posts" do
    field(:title, :string)
    field(:content, :string)
    field(:user_id, :integer)
    field(:published, :boolean)
    field(:created_at, :string)
    field(:updated_at, :string)
  end
end