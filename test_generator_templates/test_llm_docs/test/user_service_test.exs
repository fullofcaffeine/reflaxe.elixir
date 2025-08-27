defmodule UserServiceTest do
  use ExUnit.Case
  doctest Services.UserService
  
  describe "create_user/1" do
    test "creates user with valid data" do
      user_data = %{
        name: "john doe",
        email: "JOHN@EXAMPLE.COM",
        age: 30
      }
      
      result = Services.UserService.create_user(user_data)
      
      assert {:ok, user} = result
      assert user.name == "John Doe"  # Should be formatted
      assert user.email == "john@example.com"  # Should be normalized
      assert user.age == 30
      assert user.status == "active"
      assert is_binary(user.id)
      assert String.starts_with?(user.id, "usr_")
    end
    
    test "rejects invalid user data" do
      # Missing name
      result1 = Services.UserService.create_user(%{email: "test@example.com"})
      assert {:error, "Invalid user data provided"} = result1
      
      # Missing email
      result2 = Services.UserService.create_user(%{name: "John Doe"})
      assert {:error, "Invalid user data provided"} = result2
      
      # Invalid email format
      result3 = Services.UserService.create_user(%{name: "John Doe", email: "invalid-email"})
      assert {:error, "Invalid user data provided"} = result3
      
      # Null data
      result4 = Services.UserService.create_user(nil)
      assert {:error, "Invalid user data provided"} = result4
    end
    
    test "handles optional age field" do
      user_data = %{name: "Jane Doe", email: "jane@example.com"}
      
      result = Services.UserService.create_user(user_data)
      
      assert {:ok, user} = result
      assert user.age == 0  # Default value when age not provided
    end
  end
  
  describe "update_user/2" do
    test "updates user with valid data" do
      result = Services.UserService.update_user("usr_123", %{name: "jane smith"})
      
      assert {:ok, user} = result
      assert user.name == "Jane Smith"  # Should be formatted
      assert user.id == "usr_123"
    end
    
    test "rejects invalid user ID" do
      result1 = Services.UserService.update_user(nil, %{name: "Jane"})
      assert {:error, "User ID is required"} = result1
      
      result2 = Services.UserService.update_user("", %{name: "Jane"})
      assert {:error, "User ID is required"} = result2
      
      result3 = Services.UserService.update_user("   ", %{name: "Jane"})
      assert {:error, "User ID is required"} = result3
    end
  end
  
  describe "get_user_by_id/1" do
    test "returns user data for valid ID" do
      result = Services.UserService.get_user_by_id("usr_123")
      
      assert result != nil
      assert result.id == "usr_123"
      assert result.name == "Mock User"
      assert result.email == "mock@example.com"
      assert result.status == "active"
    end
    
    test "returns nil for null ID" do
      result = Services.UserService.get_user_by_id(nil)
      assert result == nil
    end
  end
  
  describe "list_users/2" do
    test "returns paginated user list with default parameters" do
      result = Services.UserService.list_users()
      
      assert result.data != nil
      assert is_list(result.data)
      assert result.page == 1
      assert result.per_page == 10
      assert result.total == 50
      assert length(result.data) <= 10
    end
    
    test "respects pagination parameters" do
      result = Services.UserService.list_users(2, 5)
      
      assert result.page == 2
      assert result.per_page == 5
      assert length(result.data) <= 5
    end
    
    test "returns users with proper structure" do
      result = Services.UserService.list_users(1, 3)
      
      assert length(result.data) > 0
      
      user = hd(result.data)
      assert is_binary(user.id)
      assert String.starts_with?(user.id, "user_")
      assert is_binary(user.name)
      assert is_binary(user.email)
      assert is_integer(user.age)
      assert user.status == "active"
    end
  end
end