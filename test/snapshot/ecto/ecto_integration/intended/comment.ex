defmodule Comment do
  use Ecto.Schema
  schema "comments" do
    
  end
  def new() do
    %{:id => nil, :body => nil, :post => nil, :post_id => nil, :user => nil, :user_id => nil, :inserted_at => nil, :updated_at => nil}
  end
end
