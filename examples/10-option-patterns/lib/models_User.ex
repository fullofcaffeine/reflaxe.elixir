defmodule User do
  use Bitwise
  @moduledoc """
  User module generated from Haxe
  
  
 * User data model for demonstration purposes.
 * 
 * This is a simple data structure used in the Option patterns example
 * to show how Option<User> provides type-safe null handling.
 
  """

  # Instance functions
  @doc """
    Get a display name for the user.
    Demonstrates how methods work with Option types.

    @return Formatted display name
  """
  @spec get_display_name() :: String.t()
  def get_display_name() do
    temp_result = nil
    if (__MODULE__.active), do: temp_result = __MODULE__.name, else: temp_result = "" <> __MODULE__.name <> " (inactive)"
    temp_result
  end

  @doc """
    Check if the user has a valid email address.
    Simple validation for demonstration purposes.

    @return True if email contains @ symbol
  """
  @spec has_valid_email() :: boolean()
  def has_valid_email() do
    __MODULE__.email != nil && case :binary.match(__MODULE__.email, "@") do {pos, _} -> pos; :nomatch -> -1 end > 0
  end

  @doc """
    Convert user to string representation for debugging.

    @return String representation of the user
  """
  @spec to_string() :: String.t()
  def to_string() do
    "User(id=" <> Integer.to_string(__MODULE__.id) <> ", name=\"" <> __MODULE__.name <> "\", email=\"" <> __MODULE__.email <> "\", active=" <> Std.string(__MODULE__.active) <> ")"
  end

end
