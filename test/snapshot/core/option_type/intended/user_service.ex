defmodule UserService do
  def find_user(name) do
    g = 0
    g1 = UserService.users
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  user = g1[g]
  g + 1
  if (user.name == name), do: {:Some, user}
  {:cont, acc}
else
  {:halt, acc}
end end)
    :None
  end
  def get_user_email(name) do
    {:Then, {:FindUser, name}, fn user -> user.email end}
  end
  def notify_user(name, message) do
    OptionTools.unwrap({:Map, {:GetUserEmail, name}, fn email -> UserService.send_email(email, message) end}, false)
  end
  defp send_email(email, message) do
    Log.trace("Sending email to " + email + ": " + message, %{:fileName => "Main.hx", :lineNumber => 225, :className => "UserService", :methodName => "sendEmail"})
    true
  end
end