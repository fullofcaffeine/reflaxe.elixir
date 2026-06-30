defmodule MyApp.Tag do
  use Ecto.Schema
  schema "tags" do

  end
  def new() do
    %{:__reflaxe_class__ => MyApp.Tag, :id => nil, :name => nil}
  end
end
