defmodule StringUtils do
  @moduledoc """
  String utility functions for the Mix project example
  """

  @doc """
  Capitalize the first letter of a string
  """
  def capitalize(s) do
    if String.length(s) > 0 do
      String.upcase(String.slice(s, 0, 1)) <> String.slice(s, 1, String.length(s))
    else
      s
    end
  end

  @doc """
  Check if a string is empty or nil
  """
  def is_empty(s) do
    s == nil or String.trim(s) == ""
  end

  @doc """
  Reverse a string
  """
  def reverse(s) do
    s |> String.graphemes() |> Enum.reverse() |> Enum.join("")
  end

  @doc """
  Count occurrences of a substring
  """
  def count_occurrences(haystack, needle) do
    if needle == "" do
      0
    else
      length(String.split(haystack, needle)) - 1
    end
  end

  @doc """
  Truncate a string with ellipsis
  """
  def truncate(s, max_length) do
    if String.length(s) <= max_length do
      s
    else
      String.slice(s, 0, max_length - 3) <> "..."
    end
  end
end