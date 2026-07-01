defmodule EctoIntegrationSimple do
  def main() do
    user = %MyApp.User{}
    user = %{user | name: "Test User"}
    user = %{user | email: "test@example.com"}
    _changeset = UserChangeset.changeset(user, %{name: "Updated", email: "new@example.com"})
    _ = CreateUsersTable.up()
    _active_users = UserQueries.active_users()
    _users = MyApp.Repo.all(MyApp.User)
    _account_users = Accounts.list_users()
    _live_view = MyAppWeb.UserLive.new()
    org = %MyApp.Organization{}
    _ = %{org | name: "Test Org"}
    post = %MyApp.Post{}
    _ = %{post | title: "Test Post"}
    comment = %MyApp.Comment{}
    _ = %{comment | body: "Test Comment"}
    nil
  end
end
