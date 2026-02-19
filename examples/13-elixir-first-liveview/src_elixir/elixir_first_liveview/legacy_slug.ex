defmodule ElixirFirstLiveview.LegacySlug do
  @moduledoc """
  Small hand-written Elixir module used to demonstrate Haxe -> Elixir interop.

  Keep this module intentionally tiny and deterministic so interop examples
  focus on the boundary pattern, not on service dependencies.
  """

  @doc """
  Normalize a label into a URL-safe slug.

  ## Examples

      iex> ElixirFirstLiveview.LegacySlug.normalize("Haxe + Elixir Interop")
      "haxe-elixir-interop"
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(value) when is_binary(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  def normalize(_), do: ""
end
