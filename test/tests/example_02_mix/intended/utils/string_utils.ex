defmodule StringUtils do
  @moduledoc """
    StringUtils module generated from Haxe

     * StringUtils - String processing utilities for Mix project
     *
     * This module demonstrates utility functions that can be shared
     * across different parts of a Mix project.
  """

  # Module functions - generated with @:module syntax sugar

  @doc """
    Processes a string with common transformations
    Trims whitespace, handles case conversion, validates format
  """
  @spec process_string(String.t()) :: String.t()
  def process_string(input) do
    (
          if ((input == nil)) do
          ""
        end
          processed = StringTools.trim(input)
          if ((processed.length == 0)) do
          "[empty]"
        end
          processed = StringUtils.remove_excess_whitespace(processed)
          processed = StringUtils.normalize_case(processed)
          processed
        )
  end

  @doc """
    Formats a display name for user interfaces
    Capitalizes first letters, handles special cases
  """
  @spec format_display_name(String.t()) :: String.t()
  def format_display_name(name) do
    (
          if (((name == nil) || (StringTools.trim(name).length == 0))) do
          "Anonymous User"
        end
          parts = StringTools.trim(name).split(" ")
          formatted = []
          g_counter = 0
          while_loop(fn -> ((g < parts.length)) end, fn -> (
          part = Enum.at(parts, g)
          g + 1
          if ((part.length > 0)) do
          (
          capitalized = part.char_at(0).to_upper_case() <> part.substr(1).to_lower_case()
          formatted ++ [capitalized]
        )
        end
        ) end)
          Enum.join(formatted, " ")
        )
  end

  @doc """
    Validates and formats email addresses

  """
  @spec process_email(String.t()) :: term()
  def process_email(email) do
    (
          if ((email == nil)) do
          %{"valid" => false, "error" => "Email is required"}
        end
          trimmed = StringTools.trim(email)
          if ((trimmed.length == 0)) do
          %{"valid" => false, "error" => "Email cannot be empty"}
        end
          if (not StringUtils.is_valid_email_format(trimmed)) do
          %{"valid" => false, "error" => "Invalid email format"}
        end
          %{"valid" => true, "email" => trimmed.to_lower_case(), "domain" => StringUtils.extract_domain(trimmed), "username" => StringUtils.extract_username(trimmed)}
        )
  end

  @doc """
    Generates a URL-friendly slug from text

  """
  @spec create_slug(String.t()) :: String.t()
  def create_slug(text) do
    if ((text == nil)) do
          ""
        end
    slug = StringTools.trim(text.to_lower_case())
    slug = EReg.new("[^a-z0-9\\s-]", "g").replace(slug, "")
    slug = EReg.new("\\s+", "g").replace(slug, "-")
    slug = EReg.new("-+", "g").replace(slug, "-")
    while_loop(fn -> ((slug.char_at(0) == "-")) end, fn -> slug = slug.substr(1) end)
    while_loop(fn -> ((slug.char_at((slug.length - 1)) == "-")) end, fn -> slug = slug.substr(0, (slug.length - 1)) end)
    slug
  end

  @doc """
    Truncates text to specified length with ellipsis

  """
  @spec truncate(String.t(), integer()) :: String.t()
  def truncate(text, max_length) do
    (
          if ((text == nil)) do
          ""
        end
          if ((text.length <= max_length)) do
          text
        end
          truncated = text.substr(0, (max_length - 3))
          last_space = truncated.last_index_of(" ")
          if ((last_space > Std.int((max_length * 0.7)))) do
          truncated = truncated.substr(0, last_space)
        end
          truncated <> "..."
        )
  end

  @doc """
    Masks sensitive information (like email addresses)

  """
  @spec mask_sensitive_info(String.t(), integer()) :: String.t()
  def mask_sensitive_info(text, visible_chars) do
    (
          if (((text == nil) || (text.length <= visible_chars))) do
          (
          temp_number = nil
          if ((text != nil)) do
          temp_number = text.length
        else
          temp_number = 4
        end
          repeat_count = temp_number
          result = ""
          (
          g_counter = 0
          g = repeat_count
          while_loop(fn -> ((g < g)) end, fn -> (
          g + 1
          result = result <> "*"
        ) end)
        )
          result
        )
        end
          visible = text.substr(0, visible_chars)
          masked_count = (text.length - visible_chars)
          masked = ""
          (
          g_counter = 0
          g = masked_count
          while_loop(fn -> ((g < g)) end, fn -> (
          g + 1
          masked = masked <> "*"
        ) end)
        )
          visible <> masked
        )
  end

  @doc "Function remove_excess_whitespace"
  @spec remove_excess_whitespace(String.t()) :: String.t()
  def remove_excess_whitespace(text) do
    EReg.new("\\s+", "g").replace(text, " ")
  end

  @doc "Function normalize_case"
  @spec normalize_case(String.t()) :: String.t()
  def normalize_case(text) do
    text.char_at(0).to_upper_case() <> text.substr(1).to_lower_case()
  end

  @doc "Function is_valid_email_format"
  @spec is_valid_email_format(String.t()) :: boolean()
  def is_valid_email_format(email) do
    (
          at_index = email.index_of("@")
          dot_index = email.last_index_of(".")
          (((at_index > 0) && (dot_index > at_index)) && (dot_index < (email.length - 1)))
        )
  end

  @doc "Function extract_domain"
  @spec extract_domain(String.t()) :: String.t()
  def extract_domain(email) do
    (
          at_index = email.index_of("@")
          temp_result = nil
          if ((at_index > 0)) do
          temp_result = email.substr((at_index + 1))
        else
          temp_result = ""
        end
          temp_result
        )
  end

  @doc "Function extract_username"
  @spec extract_username(String.t()) :: String.t()
  def extract_username(email) do
    (
          at_index = email.index_of("@")
          temp_result = nil
          if ((at_index > 0)) do
          temp_result = email.substr(0, at_index)
        else
          temp_result = email
        end
          temp_result
        )
  end

  @doc """
    Main function for compilation testing

  """
  @spec main() :: nil
  def main() do
    Log.trace("StringUtils compiled successfully for Mix project!", %{"fileName" => "./utils/StringUtils.hx", "lineNumber" => 178, "className" => "utils.StringUtils", "methodName" => "main"})
  end

end
