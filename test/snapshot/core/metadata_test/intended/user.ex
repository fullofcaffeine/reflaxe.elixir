defmodule User do
  use Ecto.Schema
  schema "users" do
    field(:name, :string)
    field(:age, :integer)
    field(:balance, :float)
  end
  def main() do
    Log.trace("Testing complex metadata syntax", %{:file_name => "MetadataTest.hx", :line_number => 14, :class_name => "User", :method_name => "main"})
  end
end
