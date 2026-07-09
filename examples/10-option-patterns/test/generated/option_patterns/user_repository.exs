defmodule OptionPatterns.UserRepository do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, OptionPatterns.UserRepository, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, OptionPatterns.UserRepository, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def users() do
    __haxe_static_get__(:users, [OptionPatterns.User.new(1, "Alice Johnson", "alice@example.com", true), OptionPatterns.User.new(2, "Bob Smith", "bob@example.com", true), OptionPatterns.User.new(3, "Charlie Brown", "charlie@example.com", false), OptionPatterns.User.new(4, "Diana Prince", "diana@example.com", true)])
  end
  def users(value) do
    __haxe_static_put__(:users, value)
  end
  def find(id) do
    if (id <= 0) do
      {:none}
    else
      _g = 0
      g_value = OptionPatterns.UserRepository.users()
      (case Enum.reduce_while(g_value, :__reflaxe_no_return__, fn user, _ ->
        if (user.id == id), do: {:halt, {:__reflaxe_return__, {:some, user}}}, else: {:cont, :__reflaxe_no_return__}
      end) do
        {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
        _ -> {:none}
      end)
    end
  end
  def find_by_email(email) do
    if (Kernel.is_nil(email) or email == "") do
      {:none}
    else
      _g = 0
      g_value = OptionPatterns.UserRepository.users()
      (case Enum.reduce_while(g_value, :__reflaxe_no_return__, fn user, _ ->
        if (user.email == email), do: {:halt, {:__reflaxe_return__, {:some, user}}}, else: {:cont, :__reflaxe_no_return__}
      end) do
        {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
        _ -> {:none}
      end)
    end
  end
  def find_first_active() do
    _g = 0
    g_value = OptionPatterns.UserRepository.users()
    (case Enum.reduce_while(g_value, :__reflaxe_no_return__, fn user, _ ->
      if (user.active), do: {:halt, {:__reflaxe_return__, {:some, user}}}, else: {:cont, :__reflaxe_no_return__}
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> {:none}
    end)
  end
  def get_user_email(id) do
    OptionTools.map(find(id), fn user -> user.email end)
  end
  def get_user_display_name(id) do
    OptionTools.unwrap(OptionTools.map(find(id), fn user -> apply(Map.get(user, :__reflaxe_class__) || Map.get(user, :__struct__), :get_display_name, [user]) end), "Unknown User")
  end
  def is_user_active(id) do
    OptionTools.unwrap(OptionTools.map(find(id), fn user -> user.active end), false)
  end
  def update_email(id, new_email) do
    if (Kernel.is_nil(new_email) or StringTools.haxe_index_of(new_email, "@", 0) < 0) do
      {:error, "Invalid email format"}
    else
      ResultTools.map(OptionTools.to_result(find(id), "User not found"), fn user -> %{user | email: new_email} end)
    end
  end
  def get_users_by_status(active) do
    result = []
    _g = 0
    g_value = OptionPatterns.UserRepository.users()
    result = Enum.reduce(g_value, result, fn user, result_acc ->
      if (user.active == active) do
        result_acc = Enum.concat(result_acc, [user])
        result_acc
      else
        result_acc
      end
    end)
    result
  end
  def create(name, email) do
    if (Kernel.is_nil(name) or name == "") do
      {:error, "Name is required"}
    else
      if (Kernel.is_nil(email) or StringTools.haxe_index_of(email, "@", 0) < 0) do
        {:error, "Valid email is required"}
      else
        email_exists = (case find_by_email(email) do
          {:some, _v} -> true
          {:none} -> false
        end)
        if (email_exists) do
          {:error, "Email already exists"}
        else
          new_id = length(OptionPatterns.UserRepository.users()) + 1
          new_user = OptionPatterns.User.new(new_id, name, email, true)
          OptionPatterns.UserRepository.users(OptionPatterns.UserRepository.users() ++ [new_user])
          {:ok, new_user}
        end
      end
    end
  end
end
