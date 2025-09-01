defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset
  schema "todos" do
    field(:name, :string)
    timestamps()
  end
  def changeset() do
    nil
  end
  def toggle_completed() do
    nil
  end
  def update_priority() do
    nil
  end
  def add_tag() do
    nil
  end
end