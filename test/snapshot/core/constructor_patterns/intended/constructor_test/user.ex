defmodule ConstructorTest.User do
  use Ecto.Schema
  schema "users" do
    
  end
  def new() do
    %{:__reflaxe_class__ => ConstructorTest.User, :id => nil, :name => nil, :email => nil}
  end
end
