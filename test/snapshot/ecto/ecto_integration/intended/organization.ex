defmodule Organization do
  use Ecto.Schema
  schema "organizations" do
    field(:name, :string)
    field(:domain, :string)
    field(:users, {:array, :string})
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
end
