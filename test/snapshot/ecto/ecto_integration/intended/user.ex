defmodule User do
  use Ecto.Schema
  schema "users" do
    
  end
  def new() do
    struct = %{:id => nil, :name => nil, :email => nil, :age => nil, :active => nil, :posts => nil, :organization => nil, :organization_id => nil, :inserted_at => nil, :updated_at => nil}
    struct = %{struct | active: true}
    struct
  end
end
