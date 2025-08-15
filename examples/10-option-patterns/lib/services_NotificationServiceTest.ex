defmodule NotificationServiceTest do
  use ExUnit.Case

  @moduledoc """
  
 * ExUnit tests for NotificationService demonstrating complex Option<T> and Result<T,E> patterns.
 * 
 * These tests verify that the notification service correctly handles business logic,
 * user preferences, error conditions, and bulk operations with type safety.
 
  """

  test "send to user succeeds for valid active user" do
    result = NotificationService.sendToUser(1, "Test message", :email)
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    record = _g
    assert record.user_id == 1
    assert record.message == "Test message"
    assert record.type == :email
    assert record.delivered
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "send to user fails for inactive user" do
    result = NotificationService.sendToUser(3, "Test message", :email)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for inactive user")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Cannot send notifications to inactive users"
    end
  end

  test "send to user fails for nonexistent user" do
    result = NotificationService.sendToUser(999, "Test message", :email)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for nonexistent user")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "User not found"
    end
  end

  test "send to user fails for empty message" do
    result = NotificationService.sendToUser(1, "", :email)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for empty message")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Message cannot be empty"
    end
  end

  test "send to user fails for null message" do
    result = NotificationService.sendToUser(1, nil, :email)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for null message")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Message cannot be empty"
    end
  end

  test "send to email succeeds for valid email" do
    result = NotificationService.sendToEmail("alice@example.com", "Email test", :email)
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    record = _g
    assert record.user_id == 1")
    assert record.message == "Email test"
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "send to email fails for nonexistent email" do
    result = NotificationService.sendToEmail("nonexistent@example.com", "Test", :email)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for nonexistent email")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Should mention email not found")
    end
  end

  test "get user preferences returns preferences for configured user" do
    prefs = NotificationService.getUserPreferences(1)
    assert OptionTools.is_some(prefs)
    case (case prefs do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case prefs do {:some, value} -> value; :none -> nil; _ -> nil end
    p = _g
    assert p.email_enabled
    assert p.sms_enabled
    refute p.push_enabled
      1 ->
        flunk("Expected to find preferences for user 1")
    end
  end

  test "get user preferences returns none for unconfigured user" do
    prefs = NotificationService.getUserPreferences(999)
    assert OptionTools.is_none(prefs)
  end

  test "is notification allowed returns true for enabled type" do
    allowed = NotificationService.isNotificationAllowed(1, :email)
    assert allowed
  end

  test "is notification allowed returns false for disabled type" do
    allowed = NotificationService.isNotificationAllowed(1, :push)
    refute allowed
  end

  test "is notification allowed returns true for user without preferences" do
    allowed = NotificationService.isNotificationAllowed(999, :email)
    assert allowed
  end

  test "send bulk returns correct success and failure counts" do
    result = NotificationService.sendBulk([1, 2, 3, 999], "Bulk test", :email)
    assert result.getSuccessCount( == 2, "Should have 2 successful sends")
    assert result.getFailureCount( == 2, "Should have 2 failed sends")
    assert result.getTotalCount( == 4, "Should have 4 total sends")
    expected_rate = 0.5
    assert result.getSuccessRate( == expected_rate, "Should have correct success rate")
  end

  test "send bulk handles empty array" do
    result = NotificationService.sendBulk([], "Test", :email)
    assert result.getSuccessCount( == 0, "Should have 0 successful sends")
    assert result.getFailureCount( == 0, "Should have 0 failed sends")
    assert result.getTotalCount( == 0, "Should have 0 total sends")
    assert result.getSuccessRate( == 0.0, "Should have 0% success rate")
  end

  test "get user notification history returns correct records" do
    NotificationService.sendToUser(1, "History test", :email)
    history = NotificationService.getUserNotificationHistory(1)
    assert length(history >= 1, "Should have at least 1 notification in history")
    _g = 0
    Enum.map(history, fn item -> 1 end)
  end

  test "get user notification history returns empty for user without history" do
    history = NotificationService.getUserNotificationHistory(999)
    assert length(history == 0, "Should have empty history for user without notifications")
  end

  test "get most recent notification returns latest record" do
    NotificationService.sendToUser(2, "First message", :email)
    NotificationService.sendToUser(2, "Second message", :s_m_s)
    recent = NotificationService.getMostRecentNotification(2)
    assert OptionTools.is_some(recent)
    case (case recent do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case recent do {:some, value} -> value; :none -> nil; _ -> nil end
    record = _g
    assert record.user_id == 2
    assert record.message == "Second message"
      1 ->
        flunk("Expected to find recent notification")
    end
  end

  test "get most recent notification returns none for user without history" do
    recent = NotificationService.getMostRecentNotification(999)
    assert OptionTools.is_none(recent)
  end

  test "set user preferences succeeds for valid user" do
    result = NotificationService.setUserPreferences(2, false, true, true)
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    prefs = _g
    refute prefs.email_enabled
    assert prefs.sms_enabled
    assert prefs.push_enabled
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
    saved_prefs = NotificationService.getUserPreferences(2)
    case (case saved_prefs do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case saved_prefs do {:some, value} -> value; :none -> nil; _ -> nil end
    p = _g
    refute p.email_enabled
      1 ->
        flunk("Preferences should be saved")
    end
  end

  test "set user preferences fails for nonexistent user" do
    result = NotificationService.setUserPreferences(999, true, true, true)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for nonexistent user")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "User not found"
    end
  end

  test "send fails when user disables notification type" do
    NotificationService.setUserPreferences(4, false, true, true)
    result = NotificationService.sendToUser(4, "Test", :email)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for disabled notification type")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Should mention disabled notification type")
    end
  end

  test "simulated delivery failure is handled" do
    result = NotificationService.sendToUser(1, "This will FAIL", :email)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected simulated delivery failure")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Simulated delivery failure"
    end
  end

end
