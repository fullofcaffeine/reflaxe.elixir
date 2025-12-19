defmodule EctoIntegrationSimple do
  def main() do
    user = %User{}
    user = %{user | name: "Test User"}
    user = %{user | email: "test@example.com"}
    changeset = MyApp.UserChangeset.changeset(user, %{:name => "Updated", :email => "new@example.com"})
    _ = MyApp.CreateUsersTable.up()
    active_users = MyApp.UserQueries.active_users()
    users = MyApp.Repo.all(User)
    account_users = MyApp.Accounts.list_users()
    live_view = MyApp.UserLive.new()
    org = %Organization{}
    org = %{org | name: "Test Org"}
    post = %Post{}
    post = %{post | title: "Test Post"}
    comment = %Comment{}
    comment = %{comment | body: "Test Comment"}
    nil
  end
end
