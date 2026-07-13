defmodule MyApp.User do
  use Ecto.Schema
  schema "users" do
    has_many(:posts, Post)
    belongs_to(:organization, Organization)
    timestamps()
  end
  def new() do
    struct = %{:__reflaxe_class__ => MyApp.User, :id => nil, :name => nil, :email => nil, :age => nil, :active => nil, :inserted_at => nil, :updated_at => nil, :posts => nil, :organization => nil, :organization_id => nil}
    struct = %{struct | active: true}
    struct
  end
end
