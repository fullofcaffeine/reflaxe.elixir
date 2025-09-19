defmodule UserChangeset do
  def changeset(user, attrs) do
    this1 = Ecto.Changeset.change(user, attrs)
    temp_changeset = this1
    temp_changeset
  end
end