defmodule UserHelper do
  @moduledoc """
    UserHelper module generated from Haxe

     * Module with edge case: special characters in name
     * Should be sanitized to valid Elixir module name
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Function format_name"
  @spec format_name(String.t(), String.t()) :: String.t()
  def format_name(first_name, last_name) do
    first_name <> " " <> last_name
  end

end
