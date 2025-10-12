defmodule InvalidSchema do
  use Ecto.Schema
  schema "items" do
    field(:valid_field, :string)
    field(:invalid_type_field, :string)
  end
end
