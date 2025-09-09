defmodule User do
  @name nil
  @email nil
  @age nil
  @bio nil
  def changeset(_struct, _user, _params) do
    nil
  end
  def validate_email_domain(_struct, changeset) do
    changeset
  end
  def update_changeset(_struct, _user, _params) do
    nil
  end
end