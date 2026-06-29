defmodule PhoenixHxTodo.ChatMessages do
  require Ecto.Query
  def list_recent() do
    query = Ecto.Query.from(t in PhoenixHxTodo.ChatMessage, [])
    messages = PhoenixHxTodo.Repo.all(query)
    messages = Enum.sort(messages, fn a, b -> (fn left, right -> (right.id - left.id) end).(a, b) < 0 end)
    _ = Enum.take(messages, 6)
  end
  def create_for_user(user, body) do
    trimmed_body = StringTools.ltrim(StringTools.rtrim(body))
    data = Kernel.struct(PhoenixHxTodo.ChatMessage)
    params = %{:body => trimmed_body, :user_id => user.id}
    _ = PhoenixHxTodo.Repo.insert(PhoenixHxTodo.ChatMessage.changeset(data, params))
  end
  def create_for_user_ok(user, body) do
    (case create_for_user(user, body) do
      {:ok, _value} -> true
      {:error, _error} -> false
    end)
  end
  def view_items() do
    Enum.map(list_recent(), &to_item/1)
  end
  defp to_item(message) do
    user = PhoenixHxTodo.Accounts.get_user(message.user_id)
    owner = if (not Kernel.is_nil(user)) do
      PhoenixHxTodo.User.display_name(user)
    else
      "Unknown user"
    end
    %{:id => message.id, :body => message.body, :owner => owner, :row_class => "chat-message"}
  end
end
