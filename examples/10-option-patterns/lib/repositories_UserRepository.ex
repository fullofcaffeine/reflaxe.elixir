defmodule UserRepository do
  use Bitwise
  @moduledoc """
  UserRepository module generated from Haxe
  
  
 * User repository demonstrating Option<T> patterns for database operations.
 * 
 * This repository shows how to use Option<T> instead of null returns,
 * providing type-safe database access patterns that prevent null pointer exceptions.
 * 
 * Key patterns demonstrated:
 * - Option<User> for nullable database results
 * - Conversion between Option and Result types
 * - Safe chaining of database operations
 * - Integration with BEAM-friendly patterns
 
  """

  # Static functions
  @doc """
    Find a user by ID.

    Returns Option<User> instead of null, making the possibility of
    "not found" explicit in the type system.

    @param id User ID to search for
    @return Some(user) if found, None if not found
  """
  @spec find(integer()) :: Option.t()
  def find(id) do
    if (id <= 0), do: :none, else: nil
    _g = 0
    _g = UserRepository.users
    Enum.find(_g, fn item -> (user.id == id) end)
    :none
  end

  @doc """
    Find a user by email address.

    Demonstrates email-based lookup with Option return type.

    @param email Email address to search for
    @return Some(user) if found, None if not found
  """
  @spec find_by_email(String.t()) :: Option.t()
  def find_by_email(email) do
    if (email == nil || email == ""), do: :none, else: nil
    _g = 0
    _g = UserRepository.users
    Enum.find(_g, fn item -> (user.email == email) end)
    :none
  end

  @doc """
    Find the first active user.

    Demonstrates filtering with Option return.

    @return Some(user) if any active user exists, None otherwise
  """
  @spec find_first_active() :: Option.t()
  def find_first_active() do
    _g = 0
    _g = UserRepository.users
    Enum.find(_g, fn item -> (user.active) end)
    :none
  end

  @doc """
    Get user email safely.

    Demonstrates chaining Option operations to safely extract nested data.

    @param id User ID
    @return Some(email) if user exists, None otherwise
  """
  @spec get_user_email(integer()) :: Option.t()
  def get_user_email(id) do
    Enum.map(OptionTools, UserRepository.find(id))
  end

  @doc """
    Get user display name with fallback.

    Shows how to use unwrap() to provide default values.

    @param id User ID
    @return Display name or "Unknown User" if not found
  """
  @spec get_user_display_name(integer()) :: String.t()
  def get_user_display_name(id) do
    OptionTools.unwrap(Enum.map(OptionTools, UserRepository.find(id)), "Unknown User")
  end

  @doc """
    Check if a user exists and is active.

    Demonstrates Option chaining with boolean logic.

    @param id User ID
    @return True if user exists and is active
  """
  @spec is_user_active(integer()) :: boolean()
  def is_user_active(id) do
    OptionTools.unwrap(Enum.map(OptionTools, UserRepository.find(id)), false)
  end

  @doc """
    Update user email with validation.

    Demonstrates converting Option to Result for error handling.

    @param id User ID
    @param newEmail New email address
    @return Ok(user) if successful, Error(message) if failed
  """
  @spec update_email(integer(), String.t()) :: Result.t()
  def update_email(id, new_email) do
    if (new_email == nil || case :binary.match(new_email, "@") do {pos, _} -> pos; :nomatch -> -1 end < 0), do: {:error, "Invalid email format"}, else: nil
    Enum.map(ResultTools, OptionTools.toResult(UserRepository.find(id), "User not found"))
  end

  @doc """
    Get users by status (active/inactive).

    Demonstrates filtering with Option integration.

    @param active Whether to get active or inactive users
    @return Array of users matching the status
  """
  @spec get_users_by_status(boolean()) :: Array.t()
  def get_users_by_status(active) do
    result = []
    _g = 0
    _g = UserRepository.users
    Enum.filter(_g, fn item -> (item.active == active) end)
    result
  end

  @doc """
    Create a new user with validation.

    Demonstrates Result type for creation operations that can fail.

    @param name User name
    @param email Email address
    @return Ok(user) if created successfully, Error(message) if validation failed
  """
  @spec create(String.t(), String.t()) :: Result.t()
  def create(name, email) do
    if (name == nil || name == ""), do: {:error, "Name is required"}, else: nil
    if (email == nil || case :binary.match(email, "@") do {pos, _} -> pos; :nomatch -> -1 end < 0), do: {:error, "Valid email is required"}, else: nil
    _g = UserRepository.findByEmail(email)
    case (case _g do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        case _g do {:some, value} -> value; :none -> nil; _ -> nil end
    {:error, "Email already exists"}
      1 ->
        nil
    end
    new_id = length(UserRepository.users) + 1
    new_user = Models.User.new(new_id, name, email, true)
    UserRepository.users ++ [new_user]
    {:ok, new_user}
  end

end
