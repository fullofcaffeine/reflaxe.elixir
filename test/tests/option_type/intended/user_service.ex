defmodule UserService do
  @moduledoc """
    UserService module generated from Haxe

     * Example service class showing Option usage patterns
  """

  # Static functions
  @doc "Generated from Haxe findUser"
  def find_user(name) do
    g_counter = 0

    g_array = UserService.users

    Enum.filter(g1, fn item -> item.name == name end)

    :error
  end

  @doc "Generated from Haxe getUserEmail"
  def get_user_email(name) do
    OptionTools.then(UserService.find_user(name), fn user -> user.email end)
  end

  @doc "Generated from Haxe notifyUser"
  def notify_user(name, message) do
    OptionTools.unwrap(OptionTools.map(UserService.get_user_email(name), fn email -> UserService.send_email(email, message) end), false)
  end

  @doc "Generated from Haxe sendEmail"
  def send_email(email, message) do
    Log.trace("Sending email to " <> email <> ": " <> message, %{"fileName" => "Main.hx", "lineNumber" => 225, "className" => "UserService", "methodName" => "sendEmail"})

    true
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
