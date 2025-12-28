defmodule UserService do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, UserService, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, UserService, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def users() do
    __haxe_static_get__(:users, [%{:name => "Alice", :email => {:some, "alice@example.com"}}, %{:name => "Bob", :email => {:none}}])
  end
  def users(value) do
    __haxe_static_put__(:users, value)
  end
  def find_user(name) do
    _g = 0
    g_value = UserService.users()
    (case Enum.reduce_while(g_value, :__reflaxe_no_return__, fn user, _ ->
  if (user.name == name), do: {:halt, {:__reflaxe_return__, {:some, user}}}, else: {:cont, :__reflaxe_no_return__}
end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> {:none}
    end)
  end
  def get_user_email(name) do
    OptionTools.then(find_user(name), fn user -> user.email end)
  end
  def notify_user(name, message) do
    OptionTools.unwrap(OptionTools.map(get_user_email(name), fn email -> send_email(email, message) end), false)
  end
  defp send_email(_, _) do
    true
  end
end
