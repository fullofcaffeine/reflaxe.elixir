defmodule UserService do
  def find_user(name) do
    _g = 0
    _g1 = UserService.users
    _ = Enum.each(g_value, (fn -> fn user ->
  if (user.name == user), do: {:some, user}
end end).())
    {:none}
  end
  def get_user_email(name) do
    MyApp.OptionTools.then(find_user(name), fn user -> user.email end)
  end
  def notify_user(name, message) do
    MyApp.OptionTools.unwrap(MyApp.OptionTools.map(get_user_email(name), fn email -> send_email(email, email) end), false)
  end
  defp send_email(email, message) do
    true
  end
end
