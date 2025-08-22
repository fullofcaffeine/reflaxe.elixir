defmodule ApplicationResultTools do
  @moduledoc """
    ApplicationResultTools module generated from Haxe

     * Helper class for Application result construction
  """

  # Static functions
  @doc """
    Create a successful application start result

  """
  @spec ok(T.t()) :: ApplicationResult.t()
  def ok(state) do
    ApplicationResult.ok(state)
  end

  @doc """
    Create an error application start result

  """
  @spec error(String.t()) :: ApplicationResult.t()
  def error(reason) do
    ApplicationResult.error(reason)
  end

  @doc """
    Create an ignore application start result

  """
  @spec ignore() :: ApplicationResult.t()
  def ignore() do
    :ignore
  end

end
