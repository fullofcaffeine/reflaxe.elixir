defmodule UserChangeset do
  def changeset(_user, _attrs) do
    (this1 = Ecto.Changeset.change(user, attrs)
this1)
  end
end