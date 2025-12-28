defmodule Post do
  use Ecto.Schema
  schema "posts" do
    
  end
  def new() do
    struct = %{:id => nil, :title => nil, :content => nil, :published => nil, :view_count => nil, :user => nil, :user_id => nil, :comments => nil, :inserted_at => nil, :updated_at => nil}
    struct = %{struct | view_count: 0}
    struct = %{struct | published: false}
    struct
  end
end
