defmodule Tag do
  use Ecto.Schema
  schema "tags" do
    
  end
  def new() do
    %{:id => nil, :name => nil}
  end
end
