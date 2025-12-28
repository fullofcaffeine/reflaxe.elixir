defmodule Organization do
  use Ecto.Schema
  schema "organizations" do
    
  end
  def new() do
    %{:id => nil, :name => nil, :domain => nil, :users => nil, :inserted_at => nil, :updated_at => nil}
  end
end
