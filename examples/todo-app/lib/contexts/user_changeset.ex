defmodule UserChangeset do
  def changeset(user, attrs) do
    fn user, attrs -> nil end
  end
end