defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset
  schema("todos", field(:name, :string)
timestamps())
end