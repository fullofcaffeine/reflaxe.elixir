defmodule Users do
  def list_users(_) do
    []
  end
  def change_user(_) do
    %{:valid => true}
  end
  def main() do
    nil
  end
  def get_user(_) do
    nil
  end
  def get_user_safe(_) do
    nil
  end
  def create_user(attrs) do
    changeset = UserChangeset.changeset(nil, attrs)
    if (not Kernel.is_nil(changeset)), do: %{:status => "ok", :user => nil}, else: %{:status => "error", :changeset => changeset}
  end
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    if (not Kernel.is_nil(changeset)), do: %{:status => "ok", :user => user}, else: %{:status => "error", :changeset => changeset}
  end
  def delete_user(user) do
    update_user(user, %{:active => false})
  end
  def search_users(_) do
    []
  end
  def users_with_posts() do
    []
  end
  def user_stats() do
    %{:total => 0, :active => 0, :inactive => 0}
  end
end
