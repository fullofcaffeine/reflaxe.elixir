defmodule UserService do
  @moduledoc """
    UserService module generated from Haxe

     * Example service class showing Option usage patterns
  """

  # Static functions
  @doc "Function find_user"
  @spec find_user(String.t()) :: Option.t()
  def find_user(name) do
    _g_counter = 0
    _g_1 = UserService.users
    (
      loop_helper = fn loop_fn, {g_1} ->
        if (g < g.length) do
          try do
            user = Enum.at(g, g)
    g = g + 1
    if (user.name == name), do: {:ok, user}, else: nil
            loop_fn.(loop_fn, {g_1})
          catch
            :break -> {g_1}
            :continue -> loop_fn.(loop_fn, {g_1})
          end
        else
          {g_1}
        end
      end
      {g_1} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    :error
  end

  @doc "Function get_user_email"
  @spec get_user_email(String.t()) :: Option.t()
  def get_user_email(name) do
    OptionTools.then(UserService.find_user(name), fn user -> user.email end)
  end

  @doc "Function notify_user"
  @spec notify_user(String.t(), String.t()) :: boolean()
  def notify_user(name, message) do
    OptionTools.unwrap(OptionTools.map(UserService.get_user_email(name), fn email -> UserService.send_email(email, message) end), false)
  end

  @doc "Function send_email"
  @spec send_email(String.t(), String.t()) :: boolean()
  def send_email(email, message) do
    Log.trace("Sending email to " <> email <> ": " <> message, %{"fileName" => "Main.hx", "lineNumber" => 225, "className" => "UserService", "methodName" => "sendEmail"})
    true
  end

end
