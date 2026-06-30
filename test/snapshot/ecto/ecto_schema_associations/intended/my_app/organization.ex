defmodule MyApp.Organization do
  use Ecto.Schema
  schema "organizations" do

  end
  def new() do
    %{:__reflaxe_class__ => MyApp.Organization, :id => nil, :name => nil}
  end
end
