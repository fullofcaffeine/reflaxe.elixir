defmodule User do
  use Ecto.Schema
  schema "users" do
    _ = has_many(:posts, Post)
    _ = belongs_to(:organization, Organization)
    _ = timestamps()
  end
  def new() do
    struct = %{:__reflaxe_class__ => User, :id => nil, :name => nil, :email => nil, :age => nil, :active => nil, :inserted_at => nil, :updated_at => nil, :posts => nil, :organization => nil, :organization_id => nil}
    struct = %{struct | active: true}
    struct
  end
end
