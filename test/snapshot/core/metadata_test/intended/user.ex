defmodule User do
  use Ecto.Schema
  import Ecto.Changeset
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password_hash, :string)
    field(:confirmed_at, :naive_datetime)
    field(:last_login_at, :naive_datetime)
    field(:active, :boolean, [default: true])
    timestamps()
  end
  def main() do
    Log.trace("Testing complex metadata syntax", %{:file_name => "MetadataTest.hx", :line_number => 14, :class_name => "User", :method_name => "main"})
  end
  
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :active])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> unique_constraint(:email)
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("user.ex", __DIR__)
User.main()