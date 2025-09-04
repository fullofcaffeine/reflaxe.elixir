defmodule UserChangeset do
  def changeset(user, attrs) do
    changeset = Ecto.Changeset_Impl_._new(user, attrs)
    changeset
  end
end