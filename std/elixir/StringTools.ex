defmodule StringTools do
  @moduledoc """
  StringTools implementation for Haxe standard library.
  Provides string manipulation functions that match Haxe's StringTools API.
  """

  @doc """
  Tells if the character at position pos is a space.
  Character codes 9,10,11,12,13 or 32 are considered spaces.
  """
  @spec is_space(String.t(), integer()) :: boolean()
  def is_space(s, pos) when is_binary(s) and is_integer(pos) do
    case String.at(s, pos) do
      nil -> false
      char ->
        case :binary.first(char) do
          c when c in [9, 10, 11, 12, 13, 32] -> true
          _ -> false
        end
    end
  end

  @doc """
  Removes leading space characters
  """
  @spec ltrim(String.t()) :: String.t()
  def ltrim(s) when is_binary(s) do
    String.trim_leading(s)
  end

  @doc """
  Removes trailing space characters
  """
  @spec rtrim(String.t()) :: String.t()
  def rtrim(s) when is_binary(s) do
    String.trim_trailing(s)
  end

  @doc """
  Removes leading and trailing space characters
  """
  @spec trim(String.t()) :: String.t()
  def trim(s) when is_binary(s) do
    String.trim(s)
  end

  @doc """
  URL encodes a string
  """
  @spec url_encode(String.t()) :: String.t()
  def url_encode(s) when is_binary(s) do
    URI.encode_www_form(s)
  end

  @doc """
  URL decodes a string
  """
  @spec url_decode(String.t()) :: String.t()
  def url_decode(s) when is_binary(s) do
    case URI.decode_www_form(s) do
      {:ok, decoded} -> decoded
      _ -> s
    end
  end

  @doc """
  HTML escapes a string
  """
  @spec html_escape(String.t(), boolean()) :: String.t()
  def html_escape(s, quotes \\ false) when is_binary(s) do
    escaped = s
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    
    if quotes do
      escaped
      |> String.replace("\"", "&quot;")
      |> String.replace("'", "&#039;")
    else
      escaped
    end
  end

  @doc """
  HTML unescapes a string
  """
  @spec html_unescape(String.t()) :: String.t()
  def html_unescape(s) when is_binary(s) do
    s
    |> String.replace("&quot;", "\"")
    |> String.replace("&#039;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
  end

  @doc """
  Checks if string starts with another string
  """
  @spec starts_with?(String.t(), String.t()) :: boolean()
  def starts_with?(s, start) when is_binary(s) and is_binary(start) do
    String.starts_with?(s, start)
  end

  @doc """
  Checks if string ends with another string
  """
  @spec ends_with?(String.t(), String.t()) :: boolean()
  def ends_with?(s, end_str) when is_binary(s) and is_binary(end_str) do
    String.ends_with?(s, end_str)
  end

  @doc """
  Replaces all occurrences of a substring
  """
  @spec replace(String.t(), String.t(), String.t()) :: String.t()
  def replace(s, sub, by) when is_binary(s) and is_binary(sub) and is_binary(by) do
    String.replace(s, sub, by)
  end

  @doc """
  Pads a string on the left with a character
  """
  @spec lpad(String.t(), String.t(), integer()) :: String.t()
  def lpad(s, c, l) when is_binary(s) and is_binary(c) and is_integer(l) do
    String.pad_leading(s, l, c)
  end

  @doc """
  Pads a string on the right with a character
  """
  @spec rpad(String.t(), String.t(), integer()) :: String.t()
  def rpad(s, c, l) when is_binary(s) and is_binary(c) and is_integer(l) do
    String.pad_trailing(s, l, c)
  end

  @doc """
  Checks if string contains another string
  """
  @spec contains(String.t(), String.t()) :: boolean()
  def contains(s, value) when is_binary(s) and is_binary(value) do
    String.contains?(s, value)
  end

  @doc """
  Fast character code access - same as charCodeAt but potentially faster
  Returns character code at given position, or 0 if out of bounds
  """
  @spec fast_code_at(String.t(), integer()) :: integer()
  def fast_code_at(s, index) when is_binary(s) and is_integer(index) do
    case String.at(s, index) do
      nil -> 0
      char -> :binary.first(char)
    end
  end

  @doc """
  Unsafe character code access - no bounds checking  
  Returns character code at given position, may crash if out of bounds
  """
  @spec unsafe_code_at(String.t(), integer()) :: integer()
  def unsafe_code_at(s, index) when is_binary(s) and is_integer(index) do
    # In Elixir, we still do safe access but could optimize later
    case String.at(s, index) do
      nil -> 0
      char -> :binary.first(char)
    end
  end

  @doc """
  Checks if a character code represents end-of-file
  Always returns false for Elixir target since we don't have EOF character
  """
  @spec is_eof(integer()) :: boolean()
  def is_eof(_c) do
    false
  end

  @doc """
  Gets UTF-16 code point at index, handling surrogates
  For UTF-16 compatibility when targeting JavaScript
  """
  @spec utf16_code_point_at(String.t(), integer()) :: integer()
  def utf16_code_point_at(s, index) when is_binary(s) and is_integer(index) do
    # Get the codepoint at the given index
    case String.at(s, index) do
      nil -> 0
      char ->
        code = :binary.first(char)
        
        # Check if it's a high surrogate (0xD800–0xDBFF)
        if code >= 0xD800 and code <= 0xDBFF do
          # Get the next character for low surrogate
          case String.at(s, index + 1) do
            nil -> code
            next_char ->
              next_code = :binary.first(next_char)
              # Check if it's a low surrogate (0xDC00–0xDFFF)
              if next_code >= 0xDC00 and next_code <= 0xDFFF do
                # Combine surrogates to get full code point
                ((code - 0xD800) * 0x400) + (next_code - 0xDC00) + 0x10000
              else
                code
              end
          end
        else
          code
        end
    end
  end

  @doc """
  Converts an integer to a hexadecimal string
  """
  @spec hex(integer(), integer() | nil) :: String.t()
  def hex(n, digits \\ nil) when is_integer(n) do
    hex_str = Integer.to_string(abs(n), 16)
    
    # Pad with zeros if digits specified
    result = if digits != nil and is_integer(digits) do
      String.pad_leading(hex_str, digits, "0")
    else
      hex_str
    end
    
    # Add negative sign if needed
    if n < 0 do
      "-" <> result
    else
      result
    end
  end

  @doc """
  Returns an iterator over the characters of a string
  Note: This returns a placeholder - actual iterator should be implemented
  """
  def iterator(s) when is_binary(s) do
    # TODO: Return proper StringIterator instance
    # For now, return a tuple that can be pattern matched
    {:string_iterator, s, 0}
  end

  @doc """
  Returns a key-value iterator over the characters of a string  
  Note: This returns a placeholder - actual iterator should be implemented
  """
  def key_value_iterator(s) when is_binary(s) do
    # TODO: Return proper StringKeyValueIterator instance
    # For now, return a tuple that can be pattern matched
    {:string_key_value_iterator, s, 0}
  end

  @doc """
  Quote argument for Unix shell execution
  """
  @spec quote_unix_arg(String.t()) :: String.t()
  def quote_unix_arg(argument) when is_binary(argument) do
    if argument == "" do
      "''"
    else
      # Check if argument needs quoting
      if Regex.match?(~r/[^a-zA-Z0-9_@%+=:,.\/-]/, argument) do
        "'" <> String.replace(argument, "'", "'\"'\"'") <> "'"
      else
        argument
      end
    end
  end

  @doc """
  Windows meta characters for shell escaping
  These are character codes that need escaping in Windows shell
  """
  def win_meta_characters do
    # Windows shell meta characters: ()%!^"<>&|
    [40, 41, 37, 33, 94, 34, 60, 62, 38, 124]
  end

  @doc """
  Quote argument for Windows shell execution
  """
  @spec quote_win_arg(String.t(), boolean()) :: String.t()
  def quote_win_arg(argument, escape_meta_characters) when is_binary(argument) do
    # Basic implementation - in practice, Elixir on Windows is rare
    # This is mainly for API compatibility
    needs_quote = String.contains?(argument, " ") or 
                   String.contains?(argument, "\t") or 
                   argument == ""
    
    result = if needs_quote do
      "\"" <> String.replace(argument, "\"", "\\\"") <> "\""
    else
      argument
    end
    
    if escape_meta_characters do
      # Escape Windows meta characters with ^
      win_meta = win_meta_characters()
      String.graphemes(result)
      |> Enum.map(fn char ->
        code = :binary.first(char)
        if code in win_meta do
          "^" <> char
        else
          char
        end
      end)
      |> Enum.join("")
    else
      result
    end
  end
end