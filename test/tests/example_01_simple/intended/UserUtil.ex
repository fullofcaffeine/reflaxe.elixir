defmodule UserUtil do
  @moduledoc """
  UserUtil - Demonstrates public and private functions
  
  This example shows how to use @:private annotation to create
  private functions (defp in Elixir) alongside public functions,
  demonstrating proper encapsulation patterns.
  """

  @doc """
  Public function - creates a new user
  Uses private helper functions for validation and formatting
  """
  def create_user(name, email) do
    # Validate inputs using private functions
    unless is_valid_name(name) do
      raise "Invalid name provided"
    end
    
    unless is_valid_email(email) do
      raise "Invalid email provided"
    end
    
    # Format and create user using private helpers
    formatted_name = format_name(name)
    normalized_email = normalize_email(email)
    
    %{
      name: formatted_name,
      email: normalized_email,
      id: generate_user_id(),
      created_at: get_current_timestamp()
    }
  end

  @doc """
  Public function - updates user information
  Demonstrates how public functions can call private helpers
  """
  def update_user(user, new_name, new_email) do
    user
    |> maybe_update_name(new_name)
    |> maybe_update_email(new_email)
  end

  @doc """
  Public function - formats user for display
  Uses private formatting helpers
  """
  def format_user_for_display(user) do
    display_name = format_display_name(user.name)
    masked_email = mask_email(user.email)
    
    "#{display_name} (#{masked_email})"
  end

  # Private helper functions - these are defp in Elixir

  @doc false
  defp is_valid_name(name) when name in [nil, ""], do: false
  defp is_valid_name(name) do
    String.length(name) >= 1 and String.length(name) <= 50
  end

  @doc false
  defp is_valid_email(email) when email in [nil, ""], do: false
  defp is_valid_email(email) do
    String.contains?(email, "@") and String.contains?(email, ".")
  end

  @doc false
  defp format_name(name) do
    name
    |> String.trim()
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc false
  defp normalize_email(email) do
    email |> String.trim() |> String.downcase()
  end

  @doc false
  defp generate_user_id do
    "user_#{:rand.uniform(1_000_000)}"
  end

  @doc false
  defp get_current_timestamp do
    "2024-01-01T00:00:00Z"
  end

  @doc false
  defp format_display_name(name) do
    case String.split(name, " ") do
      [first] -> first
      [first | rest] -> "#{first} #{String.at(List.last(rest), 0)}."
    end
  end

  @doc false
  defp mask_email(email) do
    [username, domain] = String.split(email, "@", parts: 2)
    
    case String.length(username) do
      len when len <= 2 -> "**@#{domain}"
      _ -> 
        visible = String.slice(username, 0, 2)
        "#{visible}****@#{domain}"
    end
  end

  @doc false
  defp maybe_update_name(user, nil), do: user
  defp maybe_update_name(user, new_name) do
    if is_valid_name(new_name) do
      %{user | name: format_name(new_name)}
    else
      user
    end
  end

  @doc false
  defp maybe_update_email(user, nil), do: user
  defp maybe_update_email(user, new_email) do
    if is_valid_email(new_email) do
      %{user | email: normalize_email(new_email)}
    else
      user
    end
  end
end