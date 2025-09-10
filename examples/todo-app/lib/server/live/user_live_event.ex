defmodule Server.Live.UserLiveEvent do
  def new_user() do
    {0}
  end
  def edit_user(arg0) do
    {1, arg0}
  end
  def save_user(arg0) do
    {2, arg0}
  end
  def delete_user(arg0) do
    {3, arg0}
  end
  def search(arg0) do
    {4, arg0}
  end
  def filter_status(arg0) do
    {5, arg0}
  end
  def clear_search() do
    {6}
  end
  def cancel() do
    {7}
  end
end