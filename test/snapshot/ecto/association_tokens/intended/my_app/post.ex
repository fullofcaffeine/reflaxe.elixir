defmodule MyApp.Post do
  use Ecto.Schema
  schema "posts" do
    field(:title, :string)
    field(:user_id, :integer)
    belongs_to(:user, MyApp.User)
  end

  def changeset(post, attrs) do
    post
    |> Ecto.Changeset.cast(attrs, [:title, :user_id])
    |> Ecto.Changeset.validate_required([:title, :user_id])
  end
end
