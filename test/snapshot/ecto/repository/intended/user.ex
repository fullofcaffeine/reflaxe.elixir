defmodule User do
  use Ecto.Schema
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:age, :integer)
    field(:active, :boolean)
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end
end
