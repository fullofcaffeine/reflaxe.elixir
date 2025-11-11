defmodule User do
  use Ecto.Schema
  schema "users" do
    field(:name, :string)
    field(:age, :integer)
    field(:balance, :float)
  end
  def main() do
    nil
  end
end
