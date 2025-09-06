defmodule UserChangeset do
  def changeset(user, attrs) do
    changeset = Changeset_Impl_._new(user, attrs)
    changeset
  end
end