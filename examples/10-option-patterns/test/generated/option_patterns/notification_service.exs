defmodule OptionPatterns.NotificationService do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, OptionPatterns.NotificationService, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, OptionPatterns.NotificationService, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def preferences() do
    __haxe_static_get__(:preferences, (fn ->
        g = %{}
        value = OptionPatterns.NotificationPreferences.new(true, true, false)
        g = Map.put(g, 1, value)
        value = OptionPatterns.NotificationPreferences.new(true, false, true)
        g = Map.put(g, 2, value)
        value = OptionPatterns.NotificationPreferences.new(false, false, false)
        g = Map.put(g, 3, value)
        value = OptionPatterns.NotificationPreferences.new(false, true, true)
        g = Map.put(g, 4, value)
        g
      end).())
  end
  def preferences(value) do
    __haxe_static_put__(:preferences, value)
  end
  def delivery_log() do
    __haxe_static_get__(:delivery_log, [])
  end
  def delivery_log(value) do
    __haxe_static_put__(:delivery_log, value)
  end
  def send_to_user(user_id, message, type) do
    if (Kernel.is_nil(message) or String.length(message) == 0) do
      {:error, "Message cannot be empty"}
    else
      ResultTools.flat_map(ResultTools.flat_map(ResultTools.flat_map(OptionTools.to_result(OptionPatterns.UserRepository.find(user_id), "User not found"), fn user -> if (not user.active), do: {:error, "Cannot send notifications to inactive users"}, else: {:ok, user} end), fn user -> check_user_preferences(user.id, type) end), fn user -> deliver_notification(user, message, type) end)
    end
  end
  def send_to_email(email, message, type) do
    ResultTools.flat_map(OptionTools.to_result(OptionPatterns.UserRepository.find_by_email(email), "No user found with email: #{email}"), fn user -> send_to_user(user.id, message, type) end)
  end
  def get_user_preferences(user_id) do
    this1 = OptionPatterns.NotificationService.preferences()
    prefs = _ = Map.get(this1, user_id)
    if (not Kernel.is_nil(prefs)), do: {:some, prefs}, else: {:none}
  end
  def is_notification_allowed(user_id, type) do
    OptionTools.unwrap(OptionTools.map(get_user_preferences(user_id), fn prefs -> apply(Map.get(prefs, :__reflaxe_class__) || Map.get(prefs, :__struct__), :is_allowed, [prefs, type]) end), true)
  end
  def send_bulk(user_ids, message, type) do
    attempts = Enum.map(user_ids, fn user_id -> OptionPatterns.NotificationAttempt.new(user_id, send_to_user(user_id, message, type)) end)
    successful = Enum.map(Enum.filter(attempts, fn attempt -> is_successful_attempt(attempt) end), fn attempt -> successful_record(attempt) end)
    failed = Enum.map(Enum.filter(attempts, fn attempt -> is_failed_attempt(attempt) end), fn attempt -> failed_entry(attempt) end)
    _ = OptionPatterns.BulkNotificationResult.new(successful, failed)
  end
  def get_user_notification_history(user_id) do
    result = []
    _g = 0
    g_value = OptionPatterns.NotificationService.delivery_log()
    result = Enum.reduce(g_value, result, fn record, result_acc ->
      if (record.user_id == user_id) do
        result_acc = Enum.concat(result_acc, [record])
        result_acc
      else
        result_acc
      end
    end)
    result
  end
  def get_most_recent_notification(user_id) do
    user_notifications = get_user_notification_history(user_id)
    if (length(user_notifications) == 0) do
      {:none}
    else
      most_recent = Enum.at(user_notifications, 0)
      _g = 1
      user_notifications_length = length(user_notifications)
      most_recent = Enum.reduce(1..(user_notifications_length - 1)//1, most_recent, fn i, most_recent_acc ->
        if (Reflaxe.Elixir.HaxeFloat.gte(Enum.at(user_notifications, i).timestamp, most_recent_acc.timestamp)) do
          most_recent_acc = Enum.at(user_notifications, i)
          most_recent_acc
        else
          most_recent_acc
        end
      end)
      {:some, most_recent}
    end
  end
  def set_user_preferences(user_id, email_enabled, sms_enabled, push_enabled) do
    (case OptionPatterns.UserRepository.find(user_id) do
      {:some, _v} ->
        prefs = OptionPatterns.NotificationPreferences.new(email_enabled, sms_enabled, push_enabled)
        {:ok, prefs}
      {:none} -> {:error, "User not found"}
    end)
  end
  defp is_successful_attempt(attempt) do
    (case attempt.result do
      {:ok, _value} -> true
      {:error, _error} -> false
    end)
  end
  defp is_failed_attempt(attempt) do
    (case attempt.result do
      {:ok, _value} -> false
      {:error, _error} -> true
    end)
  end
  defp successful_record(attempt) do
    (case attempt.result do
      {:ok, record} -> record
      {:error, _error} -> raise Reflaxe.Elixir.HaxeThrow, [value: "Filtered successful notifications cannot contain failures"]
    end)
  end
  defp failed_entry(attempt) do
    (case attempt.result do
      {:ok, _value} -> raise Reflaxe.Elixir.HaxeThrow, [value: "Filtered failed notifications cannot contain successes"]
      {:error, reason} -> %{user_id: attempt.user_id, reason: reason}
    end)
  end
  defp check_user_preferences(user_id, type) do
    if (not is_notification_allowed(user_id, type)) do
      {:error, "User has disabled " <> Reflaxe.Elixir.HaxeFloat.to_string(type) <> " notifications"}
    else
      OptionTools.to_result(OptionPatterns.UserRepository.find(user_id), "User not found during preference check")
    end
  end
  defp deliver_notification(user, message, type) do
    if (not apply(Map.get(user, :__reflaxe_class__) || Map.get(user, :__struct__), :has_valid_email, [user]) and type == {:email}) do
      {:error, "User has invalid email address"}
    else
      if (StringTools.haxe_index_of(message, "FAIL", 0) >= 0) do
        {:error, "Simulated delivery failure"}
      else
        record = OptionPatterns.NotificationRecord.new(user.id, message, type, System.system_time(:second), true)
        OptionPatterns.NotificationService.delivery_log(OptionPatterns.NotificationService.delivery_log() ++ [record])
        {:ok, record}
      end
    end
  end
end
