defmodule OptionPatterns.NotificationServiceTest do
  use ExUnit.Case
  test "send to user succeeds for valid active user" do
    result = OptionPatterns.NotificationService.send_to_user(1, "Test message", {:email})
    assert(match?({:ok, _}, result), "Should successfully send notification to active user")
    (case result do
      {:ok, record} ->
        assert(1 == record.user_id, "Should have correct user ID")
        assert("Test message" == record.message, "Should have correct message")
        assert({:email} == record.type, "Should have correct notification type")
        assert(record.delivered, "Should be marked as delivered")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "send to user fails for inactive user" do
    result = OptionPatterns.NotificationService.send_to_user(3, "Test message", {:email})
    assert(match?({:error, _}, result), "Should fail to send notification to inactive user")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for inactive user")
      {:error, msg} ->
        assert("Cannot send notifications to inactive users" == msg, "Should have correct error message")
    end)
  end
  test "send to user fails for nonexistent user" do
    result = OptionPatterns.NotificationService.send_to_user(999, "Test message", {:email})
    assert(match?({:error, _}, result), "Should fail to send notification to nonexistent user")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for nonexistent user")
      {:error, msg} ->
        assert("User not found" == msg, "Should have correct error message")
    end)
  end
  test "send to user fails for empty message" do
    result = OptionPatterns.NotificationService.send_to_user(1, "", {:email})
    assert(match?({:error, _}, result), "Should fail for empty message")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for empty message")
      {:error, msg} ->
        assert("Message cannot be empty" == msg, "Should have correct error message")
    end)
  end
  test "send to user fails for null message" do
    result = OptionPatterns.NotificationService.send_to_user(1, nil, {:email})
    assert(match?({:error, _}, result), "Should fail for null message")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for null message")
      {:error, msg} ->
        assert("Message cannot be empty" == msg, "Should have correct error message")
    end)
  end
  test "send to email succeeds for valid email" do
    result = OptionPatterns.NotificationService.send_to_email("alice@example.com", "Email test", {:email})
    assert(match?({:ok, _}, result), "Should successfully send notification by email")
    (case result do
      {:ok, record} ->
        assert(1 == record.user_id, "Should send to correct user (Alice has ID 1)")
        assert("Email test" == record.message, "Should have correct message")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "send to email fails for nonexistent email" do
    result = OptionPatterns.NotificationService.send_to_email("nonexistent@example.com", "Test", {:email})
    assert(match?({:error, _}, result), "Should fail for nonexistent email")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for nonexistent email")
      {:error, msg} ->
        assert(StringTools.haxe_index_of(msg, "No user found with email", 0) >= 0, "Should mention email not found")
    end)
  end
  test "get user preferences returns preferences for configured user" do
    prefs = OptionPatterns.NotificationService.get_user_preferences(1)
    assert(match?({:some, _}, prefs), "Should find preferences for user 1")
    (case prefs do
      {:some, p} ->
        assert(p.email_enabled, "User 1 should have email enabled")
        assert(p.sms_enabled, "User 1 should have SMS enabled")
        refute(p.push_enabled, "User 1 should have push disabled")
      {:none} ->
        flunk("Expected to find preferences for user 1")
    end)
  end
  test "get user preferences returns none for unconfigured user" do
    prefs = OptionPatterns.NotificationService.get_user_preferences(999)
    assert(match?({:none}, prefs), "Should not find preferences for unconfigured user")
  end
  test "is notification allowed returns true for enabled type" do
    allowed = OptionPatterns.NotificationService.is_notification_allowed(1, {:email})
    assert(allowed, "Email should be allowed for user 1")
  end
  test "is notification allowed returns false for disabled type" do
    allowed = OptionPatterns.NotificationService.is_notification_allowed(1, {:push})
    refute(allowed, "Push should be disabled for user 1")
  end
  test "is notification allowed returns true for user without preferences" do
    allowed = OptionPatterns.NotificationService.is_notification_allowed(999, {:email})
    assert(allowed, "Should default to allowed for users without preferences")
  end
  test "send bulk returns correct success and failure counts" do
    result = OptionPatterns.NotificationService.send_bulk([1, 2, 3, 999], "Bulk test", {:email})
    assert(2 == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_success_count, [result]), "Should have 2 successful sends")
    assert(2 == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_failure_count, [result]), "Should have 2 failed sends")
    assert(4 == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_total_count, [result]), "Should have 4 total sends")
    expected_rate = 0.5
    assert(expected_rate == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_success_rate, [result]), "Should have correct success rate")
  end
  test "send bulk handles empty array" do
    result = OptionPatterns.NotificationService.send_bulk([], "Test", {:email})
    assert(0 == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_success_count, [result]), "Should have 0 successful sends")
    assert(0 == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_failure_count, [result]), "Should have 0 failed sends")
    assert(0 == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_total_count, [result]), "Should have 0 total sends")
    assert(0 == apply(Map.get(result, :__reflaxe_class__) || Map.get(result, :__struct__), :get_success_rate, [result]), "Should have 0% success rate")
  end
  test "get user notification history returns correct records" do
    OptionPatterns.NotificationService.send_to_user(1, "History test", {:email})
    history = OptionPatterns.NotificationService.get_user_notification_history(1)
    assert(length(history) >= 1, "Should have at least 1 notification in history")
    _g = 0
    Enum.each(history, fn record -> assert(1 == record.user_id, "All history records should be for user 1") end)
  end
  test "get user notification history returns empty for user without history" do
    history = OptionPatterns.NotificationService.get_user_notification_history(999)
    assert(0 == length(history), "Should have empty history for user without notifications")
  end
  test "get most recent notification returns latest record" do
    OptionPatterns.NotificationService.send_to_user(2, "First message", {:email})
    OptionPatterns.NotificationService.send_to_user(2, "Second message", {:push})
    recent = OptionPatterns.NotificationService.get_most_recent_notification(2)
    assert(match?({:some, _}, recent), "Should find most recent notification")
    (case recent do
      {:some, record} ->
        assert(2 == record.user_id, "Should be for correct user")
        assert("Second message" == record.message, "Should be the most recent message")
      {:none} ->
        flunk("Expected to find recent notification")
    end)
  end
  test "get most recent notification returns none for user without history" do
    recent = OptionPatterns.NotificationService.get_most_recent_notification(999)
    assert(match?({:none}, recent), "Should not find notification for user without history")
  end
  test "set user preferences succeeds for valid user" do
    result = OptionPatterns.NotificationService.set_user_preferences(2, false, true, true)
    assert(match?({:ok, _}, result), "Should successfully set preferences for valid user")
    (case result do
      {:ok, prefs} ->
        refute(prefs.email_enabled, "Should have updated email preference")
        assert(prefs.sms_enabled, "Should have updated SMS preference")
        assert(prefs.push_enabled, "Should have updated push preference")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
    assert(OptionPatterns.NotificationService.is_notification_allowed(2, {:email}), "Default preferences remain unchanged")
  end
  test "set user preferences fails for nonexistent user" do
    result = OptionPatterns.NotificationService.set_user_preferences(999, true, true, true)
    assert(match?({:error, _}, result), "Should fail to set preferences for nonexistent user")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for nonexistent user")
      {:error, msg} ->
        assert("User not found" == msg, "Should have correct error message")
    end)
  end
  test "send fails when user disables notification type" do
    result = OptionPatterns.NotificationService.send_to_user(4, "Test", {:email})
    assert(match?({:error, _}, result), "Should fail when user has disabled notification type")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for disabled notification type")
      {:error, msg} ->
        assert(StringTools.haxe_index_of(msg, "disabled", 0) >= 0, "Should mention disabled notification type")
        assert(StringTools.haxe_index_of(msg, "notifications", 0) >= 0, "Should mention notifications")
    end)
  end
  test "simulated delivery failure is handled" do
    result = OptionPatterns.NotificationService.send_to_user(1, "This will FAIL", {:email})
    assert(match?({:error, _}, result), "Should handle simulated delivery failure")
    (case result do
      {:ok, _value} ->
        flunk("Expected simulated delivery failure")
      {:error, msg} ->
        assert("Simulated delivery failure" == msg, "Should have correct error message")
    end)
  end
end
