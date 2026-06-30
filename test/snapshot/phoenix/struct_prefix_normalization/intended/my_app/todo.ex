defmodule MyApp.Todo do
  use Ecto.Schema
  schema "todos" do

  end
  def new() do
    %{:__reflaxe_class__ => MyApp.Todo}
  end
end
