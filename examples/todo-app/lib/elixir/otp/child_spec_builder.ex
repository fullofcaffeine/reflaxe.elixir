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
    temp_string = nil
    if (id != nil), do: temp_string = id, else: temp_string = module
    {module, args}
  end

  @doc """
    Create a supervisor child spec

  """
  @spec supervisor(String.t(), Array.t(), Null.t()) :: ChildSpec.t()
  def supervisor(module, args, id) do
    temp_string = nil
    if (id != nil), do: temp_string = id, else: temp_string = module
    {module, args}
  end

  @doc """
    Create a temporary worker (won't be restarted)

  """
  @spec temp_worker(String.t(), Array.t(), Null.t()) :: ChildSpec.t()
  def temp_worker(module, args, id) do
    spec = ChildSpecBuilder.worker(module, args, id)
    spec = %{spec | restart: :temporary}
    spec
  end

end
