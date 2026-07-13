defmodule MyApp.Organization do
  use Ecto.Schema
  schema "organizations" do
    has_many(:users, User)
    timestamps()
  end
  def new() do
    %{:__reflaxe_class__ => MyApp.Organization, :id => nil, :name => nil, :domain => nil, :users => nil, :inserted_at => nil, :updated_at => nil}
  end
end
