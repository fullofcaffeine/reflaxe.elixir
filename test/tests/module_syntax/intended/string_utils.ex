defmodule StringUtils do
  @moduledoc """
    StringUtils module generated from Haxe

     * Second module to test multiple module generation
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Function is_empty"
  @spec is_empty(String.t()) :: boolean()
  def is_empty(str) do
    str == nil || str.length == 0
  end

  @doc "Function sanitize"
  @spec sanitize(String.t()) :: String.t()
  def sanitize(str) do
    str
  end

end
