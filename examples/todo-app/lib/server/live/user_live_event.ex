defmodule server.live.UserLiveEvent do
  def new_user() do
    {:NewUser}
  end
  def edit_user(arg0) do
    {:EditUser, arg0}
  end
  def save_user(arg0) do
    {:SaveUser, arg0}
  end
  def delete_user(arg0) do
    {:DeleteUser, arg0}
  end
  def search(arg0) do
    {:Search, arg0}
  end
  def filter_status(arg0) do
    {:FilterStatus, arg0}
  end
  def clear_search() do
    {:ClearSearch}
  end
  def cancel() do
    {:Cancel}
  end
end