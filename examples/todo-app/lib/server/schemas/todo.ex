defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset
  schema "todos" do
    field(:name, :string)
    timestamps()
  end
end