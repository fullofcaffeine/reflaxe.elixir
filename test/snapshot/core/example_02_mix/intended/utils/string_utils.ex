defmodule StringUtils do
  @moduledoc """
    StringUtils module generated from Haxe

     * StringUtils - String processing utilities for Mix project
     *
     * This module demonstrates utility functions that can be shared
     * across different parts of a Mix project.
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Generated from Haxe processString"
  def process_string(input) do
    if ((input == nil)) do
      ""
    else
      nil
    end

    processed = StringTools.trim(input)

    if ((processed.length == 0)) do
      "[empty]"
    else
      nil
    end

    processed = StringUtils.remove_excess_whitespace(processed)

    processed = StringUtils.normalize_case(processed)

    processed
  end


  @doc "Generated from Haxe formatDisplayName"
  def format_display_name(name) do
    if (((name == nil) || (StringTools.trim(name).length == 0))) do
      "Anonymous User"
    else
      nil
    end

    parts = StringTools.trim(name).split(" ")

    formatted = []

    g_counter = 0

    Enum.filter(parts, fn item -> item.length > 0 end)

    Enum.join(formatted, " ")
  end


  @doc "Generated from Haxe processEmail"
  def process_email(email) do
    if ((email == nil)) do
      %{"valid" => false, "error" => "Email is required"}
    else
      nil
    end

    trimmed = StringTools.trim(email)

    if ((trimmed.length == 0)) do
      %{"valid" => false, "error" => "Email cannot be empty"}
    else
      nil
    end

    if (not StringUtils.is_valid_email_format(trimmed)) do
      %{"valid" => false, "error" => "Invalid email format"}
    else
      nil
    end

    %{"valid" => true, "email" => trimmed.to_lower_case(), "domain" => StringUtils.extract_domain(trimmed), "username" => StringUtils.extract_username(trimmed)}
  end


  @doc "Generated from Haxe createSlug"
  def create_slug(text) do
    if ((text == nil)) do
      ""
    else
      nil
    end

    slug = StringTools.trim(text.to_lower_case())

    slug = EReg.new("[^a-z0-9\\s-]", "g").replace(slug, "")

    slug = EReg.new("\\s+", "g").replace(slug, "-")

    slug = EReg.new("-+", "g").replace(slug, "-")

    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((slug.char_at(0) == "-")) end,
        fn ->
          slug = slug.substr(1)
        end,
        loop_helper
      )
    )

    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((slug.char_at((slug.length - 1)) == "-")) end,
        fn ->
          slug = slug.substr(0, (slug.length - 1))
        end,
        loop_helper
      )
    )

    slug
  end


  @doc "Generated from Haxe truncate"
  def truncate(text, max_length \\ nil) do
    if ((text == nil)) do
      ""
    else
      nil
    end

    if ((text.length <= max_length)) do
      text
    else
      nil
    end

    truncated = text.substr(0, (max_length - 3))

    last_space = truncated.last_index_of(" ")

    if ((last_space > Std.int((max_length * 0.7)))), do: truncated = truncated.substr(0, last_space), else: nil

    truncated <> "..."
  end


  @doc "Generated from Haxe maskSensitiveInfo"
  def mask_sensitive_info(text, visible_chars \\ nil) do
    temp_number = nil

    if (((text == nil) || (text.length <= visible_chars))) do
      temp_number = nil
      if ((text != nil)), do: temp_number = text.length, else: temp_number = 4
      repeat_count = temp_number
      result = ""
      g_counter = 0
      g_array = repeat_count
      (
        # Simple module-level pattern (inline for now)
        loop_helper = fn condition_fn, body_fn, loop_fn ->
          if condition_fn.() do
            body_fn.()
            loop_fn.(condition_fn, body_fn, loop_fn)
          else
            nil
          end
        end
      
        loop_helper.(
          fn -> ((g_counter < g_array)) end,
          fn ->
            _i = g_counter + 1
            result = result <> "*"
          end,
          loop_helper
        )
      )
      result
    else
      nil
    end

    visible = text.substr(0, visible_chars)

    masked_count = (text.length - visible_chars)

    masked = ""

    g_counter = 0
    g_array = masked_count
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((g_counter < g_array)) end,
        fn ->
          _i = g_counter + 1
          masked = masked <> "*"
        end,
        loop_helper
      )
    )

    visible <> masked
  end


  @doc "Generated from Haxe removeExcessWhitespace"
  def remove_excess_whitespace(text) do
    EReg.new("\\s+", "g").replace(text, " ")
  end


  @doc "Generated from Haxe normalizeCase"
  def normalize_case(text) do
    text.char_at(0).to_upper_case() <> text.substr(1).to_lower_case()
  end


  @doc "Generated from Haxe isValidEmailFormat"
  def is_valid_email_format(email) do
    at_index = email.index_of("@")

    dot_index = email.last_index_of(".")

    (((at_index > 0) && (dot_index > at_index)) && (dot_index < (email.length - 1)))
  end


  @doc "Generated from Haxe extractDomain"
  def extract_domain(email) do
    temp_result = nil

    at_index = email.index_of("@")

    temp_result = nil

    if ((at_index > 0)), do: temp_result = email.substr((at_index + 1)), else: temp_result = ""

    temp_result
  end


  @doc "Generated from Haxe extractUsername"
  def extract_username(email) do
    temp_result = nil

    at_index = email.index_of("@")

    if ((at_index > 0)), do: temp_result = email.substr(0, at_index), else: temp_result = email

    temp_result
  end


  @doc "Generated from Haxe main"
  def main() do
    Log.trace("StringUtils compiled successfully for Mix project!", %{"fileName" => "./utils/StringUtils.hx", "lineNumber" => 178, "className" => "utils.StringUtils", "methodName" => "main"})
  end



  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
