defmodule UserRepositoryTest do
  use ExUnit.Case

  @moduledoc """
  
 * ExUnit tests for UserRepository demonstrating Option<T> testing patterns.
 * 
 * This test class shows how to write type-safe tests for Option and Result types,
 * verifying that the repository correctly handles null safety and error conditions.
 
  """

  test "find returns option for valid id" do
    user = UserRepository.find(1)
    assert OptionTools.is_some(user)
    case (case user do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case user do {:some, value} -> value; :none -> nil; _ -> nil end
    u = _g
    assert u.name == "Alice Johnson"
    assert u.email == "alice@example.com"
    assert u.active
      1 ->
        flunk("Expected to find user with ID 1")
    end
  end

  test "find returns none for invalid id" do
    user = UserRepository.find(999)
    assert OptionTools.is_none(user)
  end

  test "find returns none for negative id" do
    user = UserRepository.find(-1)
    assert OptionTools.is_none(user)
  end

  test "find returns none for zero id" do
    user = UserRepository.find(0)
    assert OptionTools.is_none(user)
  end

  test "find by email returns option for valid email" do
    user = UserRepository.findByEmail("bob@example.com")
    assert OptionTools.is_some(user)
    case (case user do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case user do {:some, value} -> value; :none -> nil; _ -> nil end
    u = _g
    assert u.id == 2
    assert u.name == "Bob Smith"
      1 ->
        flunk("Expected to find user with email bob@example.com")
    end
  end

  test "find by email returns none for invalid email" do
    user = UserRepository.findByEmail("nonexistent@example.com")
    assert OptionTools.is_none(user)
  end

  test "find by email returns none for empty email" do
    user = UserRepository.findByEmail("")
    assert OptionTools.is_none(user)
  end

  test "find by email returns none for null email" do
    user = UserRepository.findByEmail(nil)
    assert OptionTools.is_none(user)
  end

  test "find first active returns active user" do
    user = UserRepository.findFirstActive()
    assert OptionTools.is_some(user)
    case (case user do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case user do {:some, value} -> value; :none -> nil; _ -> nil end
    u = _g
    assert u.active
      1 ->
        flunk("Expected to find an active user")
    end
  end

  test "get user email returns email for valid user" do
    email = UserRepository.getUserEmail(1)
    assert OptionTools.is_some(email)
    assert email == {:some, "alice@example.com"}
  end

  test "get user email returns none for invalid user" do
    email = UserRepository.getUserEmail(999)
    assert OptionTools.is_none(email)
  end

  test "get user display name returns name for valid user" do
    display_name = UserRepository.getUserDisplayName(1)
    assert display_name == "Alice Johnson"
  end

  test "get user display name returns fallback for invalid user" do
    display_name = UserRepository.getUserDisplayName(999)
    assert display_name == "Unknown User"
  end

  test "is user active returns true for active user" do
    is_active = UserRepository.isUserActive(1)
    assert is_active
  end

  test "is user active returns false for inactive user" do
    is_active = UserRepository.isUserActive(3)
    refute is_active
  end

  test "is user active returns false for invalid user" do
    is_active = UserRepository.isUserActive(999)
    refute is_active
  end

  test "update email succeeds for valid user" do
    result = UserRepository.updateEmail(1, "newalice@example.com")
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    user = _g
    assert user.email == "newalice@example.com"
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "update email fails for invalid user" do
    result = UserRepository.updateEmail(999, "test@example.com")
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for invalid user")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "User not found"
    end
  end

  test "update email fails for invalid email format" do
    result = UserRepository.updateEmail(1, "invalid-email")
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for invalid email")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Invalid email format"
    end
  end

  test "get users by status returns active users" do
    active_users = UserRepository.getUsersByStatus(true)
    assert length(active_users) >= 3
    _g = 0
    Enum.map(active_users, fn item -> item.active end)
  end

  test "get users by status returns inactive users" do
    inactive_users = UserRepository.getUsersByStatus(false)
    assert length(inactive_users) >= 1
    _g = 0
    Enum.map(inactive_users, fn item -> item.active end)
  end

  test "create succeeds for valid data" do
    result = UserRepository.create("Test User", "test@example.com")
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    user = _g
    assert user.name == "Test User"
    assert user.email == "test@example.com"
    assert user.active
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "create fails for empty name" do
    result = UserRepository.create("", "test@example.com")
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for empty name")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Name is required"
    end
  end

  test "create fails for invalid email" do
    result = UserRepository.create("Test User", "invalid-email")
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for invalid email")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Valid email is required"
    end
  end

  test "create fails for duplicate email" do
    result = UserRepository.create("Test User", "alice@example.com")
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for duplicate email")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert msg == "Email already exists"
    end
  end

end
