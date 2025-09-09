defmodule UserService do
  @users nil
  def find_user(name) do
    g = 0
    g1 = users
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < length(acc_g1)) do
    user = g1[g]
    acc_g = acc_g + 1
    if (user.name == name), do: {:some, user}
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    :none
  end
  def get_user_email(name) do
    OptionTools.then(find_user(name), fn user -> user.email end)
  end
  def notify_user(name, _message) do
    OptionTools.unwrap(OptionTools.map(get_user_email(name), fn email -> send_email(email, _message) end), false)
  end
  defp send_email(email, message) do
    Log.trace("Sending email to " <> email <> ": " <> message, %{:file_name => "Main.hx", :line_number => 225, :class_name => "UserService", :method_name => "sendEmail"})
    true
  end
end