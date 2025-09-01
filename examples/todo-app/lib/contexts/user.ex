defmodule User do
  use Ecto.Schema
  import Ecto.Changeset
  schema("users", field(:name, :string)
timestamps())
end