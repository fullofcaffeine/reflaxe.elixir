defmodule ChildSpecBuilder do
  @moduledoc """
    ChildSpecBuilder module generated from Haxe

     * Helper class for creating child specifications
  """

  # Static functions
  @doc """
    Create a worker child spec

  """
  @spec worker(String.t(), Array.t(), Null.t()) :: ChildSpec.t()
  def worker(module, args, id) do
    tempString = if ((id != nil)), do: id, else: module
  end

  @doc """
    Create a supervisor child spec

  """
  @spec supervisor(String.t(), Array.t(), Null.t()) :: ChildSpec.t()
  def supervisor(module, args, id) do
    tempString = if ((id != nil)), do: id, else: module
  end

  @doc """
    Create a temporary worker (won't be restarted)

  """
  @spec temp_worker(String.t(), Array.t(), Null.t()) :: ChildSpec.t()
  def temp_worker(module, args, id) do
    (
          spec = ChildSpecBuilder.worker(module, args, id)
          %{spec | restart: :temporary}
          spec
        )
  end

end
