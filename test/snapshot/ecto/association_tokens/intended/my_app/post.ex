defmodule MyApp.Post do
  use Ecto.Schema
  schema "posts" do
    _ = field(:title, :string)
    _ = field(:user_id, :integer)
    _ = belongs_to(:user, MyApp.User)
  end

  def changeset(post, attrs) do
    post
    |> Ecto.Changeset.cast(attrs, [:title, :user_id])
    |> Ecto.Changeset.validate_required([:title, :user_id])
  end
end
