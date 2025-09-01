defmodule Users do
  def list_users(filter) do
    TodoApp.Repo.all(User)
  end
  def change_user(user) do
    %{:valid => true}
  end
  def main() do
    Log.trace("Users context with User schema compiled successfully!", %{:fileName => "src_haxe/server/contexts/Users.hx", :lineNumber => 66, :className => "contexts.Users", :methodName => "main"})
  end
  def get_user(id) do
    TodoApp.Repo.get!(User, id)
  end
  def get_user_safe(id) do
    TodoApp.Repo.get(User, id)
  end
  def create_user(attrs) do
    result = (

            changeset = User.changeset(%User{}, attrs)
            case TodoApp.Repo.insert(changeset) do
                {:ok, user} -> %{status: "ok", user: user}
                {:error, changeset} -> %{status: "error", changeset: changeset}
            end
        
)
    result
  end
  def update_user(user, attrs) do
    result = (

            changeset = User.changeset(user, attrs)
            case TodoApp.Repo.update(changeset) do
                {:ok, user} -> %{status: "ok", user: user}
                {:error, changeset} -> %{status: "error", changeset: changeset}
            end
        
)
    result
  end
  def delete_user(user) do
    result = 
            case TodoApp.Repo.delete(user) do
                {:ok, user} -> %{status: "ok", user: user}
                {:error, _} -> %{status: "error"}
            end
        
    result
  end
  def search_users(term) do
    []
  end
  defp users_with_posts() do
    []
  end
  def user_stats() do
    %{:total => 0, :active => 0, :inactive => 0}
  end
end