defmodule UserRegistrationTest do
  use ExUnit.Case

  test "registers valid users with parsed domain values" do
    assert {:ok, user} =
             UserRegistration.register_user(
               "Alice123",
               "  alice@example.com  ",
               "  Alice Smith  ",
               "28"
             )

    assert UserId_Impl_.to_string(user.user_id) == "Alice123"
    assert Email_Impl_.to_string(user.email) == "alice@example.com"
    assert Email_Impl_.get_domain(user.email) == "example.com"
    assert NonEmptyString_Impl_.to_string(user.display_name) == "Alice Smith"
    assert PositiveInt_Impl_.to_int(user.age) == 28
  end

  test "rejects invalid registration inputs with domain-specific errors" do
    assert {:error, "Invalid User ID: User ID too short" <> _} =
             UserRegistration.register_user("ab", "alice@example.com", "Alice", "28")

    assert {:error, "Invalid Email: Invalid email address: invalid-email"} =
             UserRegistration.register_user("alice123", "invalid-email", "Alice", "28")

    assert {:error, "Invalid Display Name: String cannot be empty or whitespace-only"} =
             UserRegistration.register_user("alice123", "alice@example.com", "   ", "28")

    assert {:error, "Invalid Age: \"not-a-number\" is not a number"} =
             UserRegistration.register_user(
               "alice123",
               "alice@example.com",
               "Alice",
               "not-a-number"
             )

    assert {:error, "Invalid Age: Value must be positive, got: 0"} =
             UserRegistration.register_user("alice123", "alice@example.com", "Alice", "0")
  end

end
