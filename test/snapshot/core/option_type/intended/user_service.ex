defmodule UserService do
  def find_user(name) do
    g = 0
    g1 = UserService.users
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1.length) do
    user = g1[g]
    acc_g = acc_g + 1
    if (user.name == name), do: {:Some, user}
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    :none
  end
  def get_user_email(name) do
    {:Then, {:FindUser, name}, fn user -> user.email end}
  end
  def notify_user(name, message) do
    OptionTools.unwrap({:Map, {:GetUserEmail, name}, fn email -> send_email(email, message) end}, false)
  end
  defp send_email(email, message) do
    Log.trace("Sending email to " <> email <> ": " <> message, %{:fileName => "Main.hx", :lineNumber => 225, :className => "UserService", :methodName => "sendEmail"})
    true
  end
end