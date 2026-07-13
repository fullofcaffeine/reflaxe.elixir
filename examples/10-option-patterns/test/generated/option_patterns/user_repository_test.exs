defmodule OptionPatterns.UserRepositoryTest do
  use ExUnit.Case
  test "find returns option for valid id" do
    user = OptionPatterns.UserRepository.find(1)
    assert(match?({:some, _}, user), "Should find user with ID 1")
    (case user do
      {:some, u} ->
        assert("Alice Johnson" == u.name, "Should have correct name")
        assert("alice@example.com" == u.email, "Should have correct email")
        assert(u.active, "Should be active")
      {:none} ->
        flunk("Expected to find user with ID 1")
    end)
  end
  test "find returns none for invalid id" do
    user = OptionPatterns.UserRepository.find(999)
    assert(match?({:none}, user), "Should not find user with invalid ID")
  end
  test "find returns none for negative id" do
    user = OptionPatterns.UserRepository.find(-1)
    assert(match?({:none}, user), "Should not find user with negative ID")
  end
  test "find returns none for zero id" do
    user = OptionPatterns.UserRepository.find(0)
    assert(match?({:none}, user), "Should not find user with zero ID")
  end
  test "find by email returns option for valid email" do
    user = OptionPatterns.UserRepository.find_by_email("bob@example.com")
    assert(match?({:some, _}, user), "Should find user with valid email")
    (case user do
      {:some, u} ->
        assert(2 == u.id, "Should have correct ID")
        assert("Bob Smith" == u.name, "Should have correct name")
      {:none} ->
        flunk("Expected to find user with email bob@example.com")
    end)
  end
  test "find by email returns none for invalid email" do
    user = OptionPatterns.UserRepository.find_by_email("nonexistent@example.com")
    assert(match?({:none}, user), "Should not find user with invalid email")
  end
  test "find by email returns none for empty email" do
    user = OptionPatterns.UserRepository.find_by_email("")
    assert(match?({:none}, user), "Should not find user with empty email")
  end
  test "find by email returns none for null email" do
    user = OptionPatterns.UserRepository.find_by_email(nil)
    assert(match?({:none}, user), "Should not find user with null email")
  end
  test "find first active returns active user" do
    user = OptionPatterns.UserRepository.find_first_active()
    assert(match?({:some, _}, user), "Should find an active user")
    (case user do
      {:some, u} ->
        assert(u.active, "Found user should be active")
      {:none} ->
        flunk("Expected to find an active user")
    end)
  end
  test "get user email returns email for valid user" do
    email = OptionPatterns.UserRepository.get_user_email(1)
    assert(match?({:some, _}, email), "Should get email for valid user")
    assert({:some, "alice@example.com"} == email, "Should have correct email")
  end
  test "get user email returns none for invalid user" do
    email = OptionPatterns.UserRepository.get_user_email(999)
    assert(match?({:none}, email), "Should not get email for invalid user")
  end
  test "get user display name returns name for valid user" do
    display_name = OptionPatterns.UserRepository.get_user_display_name(1)
    assert("Alice Johnson" == display_name, "Should return user's display name")
  end
  test "get user display name returns fallback for invalid user" do
    display_name = OptionPatterns.UserRepository.get_user_display_name(999)
    assert("Unknown User" == display_name, "Should return fallback for invalid user")
  end
  test "is user active returns true for active user" do
    is_active = OptionPatterns.UserRepository.is_user_active(1)
    assert(is_active, "User 1 should be active")
  end
  test "is user active returns false for inactive user" do
    is_active = OptionPatterns.UserRepository.is_user_active(3)
    refute(is_active, "User 3 should be inactive")
  end
  test "is user active returns false for invalid user" do
    is_active = OptionPatterns.UserRepository.is_user_active(999)
    refute(is_active, "Invalid user should return false")
  end
  test "update email succeeds for valid user" do
    result = OptionPatterns.UserRepository.update_email(1, "newalice@example.com")
    assert(match?({:ok, _}, result), "Should successfully update email for valid user")
    (case result do
      {:ok, user} ->
        assert("newalice@example.com" == user.email, "Should have updated email")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "update email fails for invalid user" do
    result = OptionPatterns.UserRepository.update_email(999, "test@example.com")
    assert(match?({:error, _}, result), "Should fail to update email for invalid user")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for invalid user")
      {:error, msg} ->
        assert("User not found" == msg, "Should have correct error message")
    end)
  end
  test "update email fails for invalid email format" do
    result = OptionPatterns.UserRepository.update_email(1, "invalid-email")
    assert(match?({:error, _}, result), "Should fail for invalid email format")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for invalid email")
      {:error, msg} ->
        assert("Invalid email format" == msg, "Should have correct error message")
    end)
  end
  test "get users by status returns active users" do
    active_users = OptionPatterns.UserRepository.get_users_by_status(true)
    assert(length(active_users) >= 3, "Should have at least 3 active users")
    _g = 0
    Enum.each(active_users, fn user -> assert(user.active, "All returned users should be active") end)
  end
  test "get users by status returns inactive users" do
    inactive_users = OptionPatterns.UserRepository.get_users_by_status(false)
    assert(length(inactive_users) >= 1, "Should have at least 1 inactive user")
    _g = 0
    Enum.each(inactive_users, fn user -> refute(user.active, "All returned users should be inactive") end)
  end
  test "create succeeds for valid data" do
    result = OptionPatterns.UserRepository.create("Test User", "test@example.com")
    assert(match?({:ok, _}, result), "Should successfully create user with valid data")
    (case result do
      {:ok, user} ->
        assert("Test User" == user.name, "Should have correct name")
        assert("test@example.com" == user.email, "Should have correct email")
        assert(user.active, "New user should be active")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "create fails for empty name" do
    result = OptionPatterns.UserRepository.create("", "test@example.com")
    assert(match?({:error, _}, result), "Should fail for empty name")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for empty name")
      {:error, msg} ->
        assert("Name is required" == msg, "Should have correct error message")
    end)
  end
  test "create fails for invalid email" do
    result = OptionPatterns.UserRepository.create("Test User", "invalid-email")
    assert(match?({:error, _}, result), "Should fail for invalid email")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for invalid email")
      {:error, msg} ->
        assert("Valid email is required" == msg, "Should have correct error message")
    end)
  end
  test "create fails for duplicate email" do
    result = OptionPatterns.UserRepository.create("Test User", "bob@example.com")
    assert(match?({:error, _}, result), "Should fail for duplicate email")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for duplicate email")
      {:error, msg} ->
        assert("Email already exists" == msg, "Should have correct error message")
    end)
  end
end
