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
    if (processed.length == 0), do: "[empty]", else: nil
    processed
    processed
      |> removeExcessWhitespace()
      |> normalizeCase()
  end

  @doc """
    Formats a display name for user interfaces
    Capitalizes first letters, handles special cases
  """
  @spec format_display_name(String.t()) :: String.t()
  def format_display_name(name) do
    if (name == nil || StringTools.trim(name).length == 0), do: "Anonymous User", else: nil
    parts = String.split(StringTools.trim(name), " ")
    formatted = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < parts.length) do
          try do
            part = Enum.at(parts, g)
          g = g + 1
          if (part.length > 0) do
      capitalized = part.char_at(0).to_upper_case() <> String.slice(part, 1..-1).to_lower_case()
      formatted ++ [capitalized]
    end
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    Enum.join(formatted, " ")
  end

  @doc """
    Validates and formats email addresses

  """
  @spec process_email(String.t()) :: term()
  def process_email(email) do
    if (email == nil), do: %{"valid" => false, "error" => "Email is required"}, else: nil
    trimmed = StringTools.trim(email)
    if (trimmed.length == 0), do: %{"valid" => false, "error" => "Email cannot be empty"}, else: nil
    if (!StringUtils.is_valid_email_format(trimmed)), do: %{"valid" => false, "error" => "Invalid email format"}, else: nil
    %{"valid" => true, "email" => trimmed.to_lower_case(), "domain" => StringUtils.extract_domain(trimmed), "username" => StringUtils.extract_username(trimmed)}
  end

  @doc """
    Generates a URL-friendly slug from text

  """
  @spec create_slug(String.t()) :: String.t()
  def create_slug(text) do
    if (text == nil), do: "", else: nil
    slug = StringTools.trim(text.to_lower_case())
    (
      loop_helper = fn loop_fn, {slug} ->
        if (slug.char_at(0) == "-") do
          try do
            slug = String.slice(slug, 1..-1)
          loop_fn.({String.slice(slug, 1..-1)})
            loop_fn.(loop_fn, {slug})
          catch
            :break -> {slug}
            :continue -> loop_fn.(loop_fn, {slug})
          end
        else
          {slug}
        end
      end
      {slug} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    (
      loop_helper = fn loop_fn, {slug} ->
        if (slug.char_at(slug.length - 1) == "-") do
          try do
            slug = String.slice(slug, 0, slug.length - 1)
          loop_fn.({String.slice(slug, 0, slug.length - 1)})
            loop_fn.(loop_fn, {slug})
          catch
            :break -> {slug}
            :continue -> loop_fn.(loop_fn, {slug})
          end
        else
          {slug}
        end
      end
      {slug} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    slug
    slug
      |> replace("")
      |> replace("-")
      |> replace("-")
  end

  @doc """
    Truncates text to specified length with ellipsis

  """
  @spec truncate(String.t(), integer()) :: String.t()
  def truncate(text, max_length) do
    if (text == nil), do: "", else: nil
    if (text.length <= max_length), do: text, else: nil
    truncated = String.slice(text, 0, max_length - 3)
    last_space = truncated.last_index_of(" ")
    if (last_space > Std.int(max_length * 0.7)), do: truncated = String.slice(truncated, 0, last_space), else: nil
    truncated <> "..."
  end

  @doc """
    Masks sensitive information (like email addresses)

  """
  @spec mask_sensitive_info(String.t(), integer()) :: String.t()
  def mask_sensitive_info(text, visible_chars) do
    if (text == nil || text.length <= visible_chars) do
      temp_number = nil
      temp_number = if (text != nil), do: text.length, else: 4
      repeat_count = temp_number
      result = ""
      _g_counter = 0
      _g_1 = repeat_count
      (
        loop_helper = fn loop_fn, {result} ->
          if (g < g) do
            try do
              i = g = g + 1
      result = result <> "*"
              loop_fn.(loop_fn, {result})
            catch
              :break -> {result}
              :continue -> loop_fn.(loop_fn, {result})
            end
          else
            {result}
          end
        end
        {result} = try do
          loop_helper.(loop_helper, {nil})
        catch
          :break -> {nil}
        end
      )
      result
    end
    visible = String.slice(text, 0, visible_chars)
    masked_count = text.length - visible_chars
    masked = ""
    _g_counter = 0
    _g_1 = masked_count
    (
      loop_helper = fn loop_fn, {masked} ->
        if (g < g) do
          try do
            i = g = g + 1
    masked = masked <> "*"
            loop_fn.(loop_fn, {masked})
          catch
            :break -> {masked}
            :continue -> loop_fn.(loop_fn, {masked})
          end
        else
          {masked}
        end
      end
      {masked} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
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
    text.char_at(0).to_upper_case() <> String.slice(text, 1..-1).to_lower_case()
  end

  @doc "Function is_valid_email_format"
  @spec is_valid_email_format(String.t()) :: boolean()
  def is_valid_email_format(email) do
    at_index = email.index_of("@")
    dot_index = email.last_index_of(".")
    at_index > 0 && dot_index > at_index && dot_index < email.length - 1
  end

  @doc "Function extract_domain"
  @spec extract_domain(String.t()) :: String.t()
  def extract_domain(email) do
    at_index = email.index_of("@")
    temp_result = nil
    temp_result = if (at_index > 0), do: String.slice(email, at_index + 1..-1), else: ""
    temp_result
  end

  @doc "Function extract_username"
  @spec extract_username(String.t()) :: String.t()
  def extract_username(email) do
    at_index = email.index_of("@")
    temp_result = nil
    temp_result = if (at_index > 0), do: String.slice(email, 0, at_index), else: email
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
