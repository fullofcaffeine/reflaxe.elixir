defmodule Post do
  use Ecto.Schema
  schema "posts" do
    _ = belongs_to(:organization, Organization)
    _ = many_to_many(:tags, Tag, [join_through: "posts_tags"])
    _ = timestamps()
  end
  def new() do
    %{:__reflaxe_class__ => Post, :id => nil, :title => nil, :organization => nil, :tags => nil}
  end
end
