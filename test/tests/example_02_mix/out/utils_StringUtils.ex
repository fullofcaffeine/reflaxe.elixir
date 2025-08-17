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
    if (input == nil), do: "", else: nil
    processed = StringTools.trim(input)
    if (String.length(processed) == 0), do: "[empty]", else: nil
    processed = StringUtils.removeExcessWhitespace(processed)
    processed = StringUtils.normalizeCase(processed)
    processed
  end

  @doc """
    Formats a display name for user interfaces
    Capitalizes first letters, handles special cases
  """
  @spec format_display_name(String.t()) :: String.t()
  def format_display_name(name) do
    if (name == nil || String.length(StringTools.trim(name)) == 0), do: "Anonymous User", else: nil
    parts = String.split(StringTools.trim(name), " ")
    formatted = []
    _g = 0
    Enum.filter(parts, fn item -> (item.length > 0) end)
    Enum.join(formatted, " ")
  end

  @doc """
    Validates and formats email addresses

  """
  @spec process_email(String.t()) :: term()
  def process_email(email) do
    if (email == nil), do: %{"valid" => false, "error" => "Email is required"}, else: nil
    trimmed = StringTools.trim(email)
    if (String.length(trimmed) == 0), do: %{"valid" => false, "error" => "Email cannot be empty"}, else: nil
    if (!StringUtils.isValidEmailFormat(trimmed)), do: %{"valid" => false, "error" => "Invalid email format"}, else: nil
    %{"valid" => true, "email" => String.downcase(trimmed), "domain" => StringUtils.extractDomain(trimmed), "username" => StringUtils.extractUsername(trimmed)}
  end

  @doc """
    Generates a URL-friendly slug from text

  """
  @spec create_slug(String.t()) :: String.t()
  def create_slug(text) do
    if (text == nil), do: "", else: nil
    slug = StringTools.trim(String.downcase(text))
    slug = EReg.new("[^a-z0-9\\s-]", "g").replace(slug, "")
    slug = EReg.new("\\s+", "g").replace(slug, "-")
    slug = EReg.new("-+", "g").replace(slug, "-")
    (
      try do
        loop_fn = fn {slug} ->
          if (String.at(slug, 0) == "-") do
            try do
              # slug updated to String.slice(slug, 1..-1)
          loop_fn.({String.slice(slug, 1..-1)})
            catch
              :break -> {slug}
              :continue -> loop_fn.({slug})
            end
          else
            {slug}
          end
        end
        loop_fn.({slug})
      catch
        :break -> {slug}
      end
    )
    (
      try do
        loop_fn = fn {slug} ->
          if (String.at(slug, String.length(slug) - 1) == "-") do
            try do
              # slug updated to String.slice(slug, 0, String.length(slug) - 1)
          loop_fn.({String.slice(slug, 0, String.length(slug) - 1)})
            catch
              :break -> {slug}
              :continue -> loop_fn.({slug})
            end
          else
            {slug}
          end
        end
        loop_fn.({slug})
      catch
        :break -> {slug}
      end
    )
    slug
  end

  @doc """
    Truncates text to specified length with ellipsis

  """
  @spec truncate(String.t(), integer()) :: String.t()
  def truncate(text, max_length) do
    if (text == nil), do: "", else: nil
    if (String.length(text) <= max_length), do: text, else: nil
    truncated = String.slice(text, 0, max_length - 3)
    last_space = truncated.lastIndexOf(" ")
    if (last_space > Std.int(max_length * 0.7)), do: truncated = String.slice(truncated, 0, last_space), else: nil
    truncated <> "..."
  end

  @doc """
    Masks sensitive information (like email addresses)

  """
  @spec mask_sensitive_info(String.t(), integer()) :: String.t()
  def mask_sensitive_info(text, visible_chars) do
    if (text == nil || String.length(text) <= visible_chars) do
      temp_number = nil
      if (text != nil), do: temp_number = String.length(text), else: temp_number = 4
      repeat_count = temp_number
      result = ""
      _g = 0
      _g = repeat_count
      (
        try do
          loop_fn = fn {result} ->
            if (_g < _g) do
              try do
                _g = _g + 1
            # result updated with <> "*"
            loop_fn.({result <> "*"})
              catch
                :break -> {result}
                :continue -> loop_fn.({result})
              end
            else
              {result}
            end
          end
          loop_fn.({result})
        catch
          :break -> {result}
        end
      )
      result
    end
    visible = String.slice(text, 0, visible_chars)
    masked_count = String.length(text) - visible_chars
    masked = ""
    _g = 0
    _g = masked_count
    (
      try do
        loop_fn = fn {masked} ->
          if (_g < _g) do
            try do
              _g = _g + 1
          # masked updated with <> "*"
          loop_fn.({masked <> "*"})
            catch
              :break -> {masked}
              :continue -> loop_fn.({masked})
            end
          else
            {masked}
          end
        end
        loop_fn.({masked})
      catch
        :break -> {masked}
      end
    )
    visible <> masked
  end

  @doc "Function remove_excess_whitespace"
  @spec remove_excess_whitespace(String.t()) :: String.t()
  def remove_excess_whitespace(text) do
    EReg.new("\\s+", "g").replace(text, " ")
  end

  @doc "Function normalize_case"
  @spec normalize_case(String.t()) :: String.t()
  def normalize_case(text) do
    String.upcase(String.at(text, 0)) <> String.downcase(String.slice(text, 1..-1))
  end

  @doc "Function is_valid_email_format"
  @spec is_valid_email_format(String.t()) :: boolean()
  def is_valid_email_format(email) do
    at_index = case :binary.match(email, "@") do {pos, _} -> pos; :nomatch -> -1 end
    dot_index = email.lastIndexOf(".")
    at_index > 0 && dot_index > at_index && dot_index < String.length(email) - 1
  end

  @doc "Function extract_domain"
  @spec extract_domain(String.t()) :: String.t()
  def extract_domain(email) do
    at_index = case :binary.match(email, "@") do {pos, _} -> pos; :nomatch -> -1 end
    temp_result = nil
    if (at_index > 0), do: temp_result = String.slice(email, at_index + 1..-1), else: temp_result = ""
    temp_result
  end

  @doc "Function extract_username"
  @spec extract_username(String.t()) :: String.t()
  def extract_username(email) do
    at_index = case :binary.match(email, "@") do {pos, _} -> pos; :nomatch -> -1 end
    temp_result = nil
    if (at_index > 0), do: temp_result = String.slice(email, 0, at_index), else: temp_result = email
    temp_result
  end

  @doc """
    Main function for compilation testing

  """
  @spec main() :: nil
  def main() do
    Log.trace("StringUtils compiled successfully for Mix project!", %{"fileName" => "./utils/StringUtils.hx", "lineNumber" => 178, "className" => "utils.StringUtils", "methodName" => "main"})
  end

end
