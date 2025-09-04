defmodule Comment do
  use Ecto.Schema
  import Ecto.Changeset
  schema "comments" do
    field(:name, :string)
    field(:email, :string)
    field(:password_hash, :string)
    field(:confirmed_at, :naive_datetime)
    field(:last_login_at, :naive_datetime)
    field(:active, :boolean, [default: true])
    timestamps()
  end
end