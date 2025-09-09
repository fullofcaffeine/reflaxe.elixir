defmodule UserChangeset do
  def changeset(user, attrs) do
    (Changeset_Impl_._new(user, attrs))
  end
end