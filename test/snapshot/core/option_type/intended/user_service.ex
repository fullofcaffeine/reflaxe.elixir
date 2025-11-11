defmodule UserService do
  def find_user(name) do
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, (fn -> fn _, acc ->
  if (0 < length(UserService.users)) do
    user = UserService.users[0]
    if (user.name == name), do: {:some, user}
    {:cont, acc}
  else
    {:halt, acc}
  end
end end).())
    {:none}
  end
  def get_user_email(name) do
    MyApp.OptionTools.then(find_user(name), fn user -> user.email end)
  end
  def notify_user(name, message) do
    MyApp.OptionTools.unwrap(OptionTools.map(get_user_email(name), fn email -> send_email(email, message) end), false)
  end
  defp send_email(email, message) do
    true
  end
end
