defmodule MyApp.Comment do
  use Ecto.Schema
  schema "comments" do
    belongs_to(:post, Post)
    belongs_to(:user, User)
    timestamps()
  end
  def new() do
    %{:__reflaxe_class__ => MyApp.Comment, :id => nil, :body => nil, :post => nil, :post_id => nil, :user => nil, :user_id => nil, :inserted_at => nil, :updated_at => nil}
  end
end
