defmodule UserChangeset do
  def changeset(user, attrs) do
    (this1 = Ecto.Changeset.change(user, attrs)
this1)
  end
end