defmodule User do
  def changeset(_, _, _) do
    nil
  end
  def validate_email_domain(_, changeset) do
    changeset
  end
  def update_changeset(_, _, _) do
    nil
  end
end
