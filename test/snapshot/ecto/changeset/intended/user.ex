defmodule User do
  def changeset(_struct, _user, _value) do
    nil
  end
  def validate_email_domain(_struct, changeset) do
    changeset
  end
  def update_changeset(_struct, _user, _value) do
    nil
  end
end
