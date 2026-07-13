defmodule MyApp.Post do
  use Ecto.Schema
  schema "posts" do
    belongs_to(:organization, MyApp.Organization)
    many_to_many(:tags, MyApp.Tag, [join_through: "posts_tags"])
    timestamps()
  end
  def new() do
    %{:__reflaxe_class__ => MyApp.Post, :id => nil, :title => nil, :organization => nil, :organization_id => nil, :tags => nil}
  end
end
