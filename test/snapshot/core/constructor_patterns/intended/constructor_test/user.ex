defmodule ConstructorTest.User do
  use Ecto.Schema
  schema "users" do
    
  end
  def new() do
    %{:id => nil, :name => nil, :email => nil}
  end
end
