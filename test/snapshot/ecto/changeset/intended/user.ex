defmodule User do
  @name nil
  @email nil
  @age nil
  @bio nil
  def changeset(struct, _user, _params) do
    nil
  end
  def validate_email_domain(struct, changeset) do
    changeset
  end
  def update_changeset(struct, _user, _params) do
    nil
  end
end