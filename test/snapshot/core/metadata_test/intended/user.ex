defmodule User do
  use Ecto.Schema
  schema "users" do
    _ = field(:name, :string)
    _ = field(:age, :integer)
    _ = field(:balance, :float)
  end
  def main() do
    nil
  end
  
  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:name, :age, :balance])
    |> Ecto.Changeset.validate_required([:name, :age, :balance])
  end
end
