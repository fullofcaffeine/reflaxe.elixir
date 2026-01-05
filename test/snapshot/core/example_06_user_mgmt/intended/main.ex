defmodule Main do
  def main() do
    _user_changeset = Users.change_user(nil)
    new_user_attrs = %{:name => "John Doe", :email => "john@example.com", :age => 30, :active => true}
    _create_result = Users.create_user(new_user_attrs)
    _all_users = Users.list_users(nil)
    _search_results = Users.search_users("john")
    _active_users = Users.list_users(%{:active => true, :min_age => 18})
    _stats = Users.user_stats()
    _users_with_posts = Users.users_with_posts()
    nil
  end
end
