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
    temp_string = if (id != nil), do: id, else: module
    %{id: if(id != nil, do: id, else: module), start: {module, :start_link, args}, restart: :permanent, shutdown: {:timeout, 5000}, type: :worker, modules: [module]}
  end

  @doc """
    Create a supervisor child spec

  """
  @spec supervisor(String.t(), Array.t(), Null.t()) :: ChildSpec.t()
  def supervisor(module, args, id) do
    temp_string = nil
    temp_string = if (id != nil), do: id, else: module
    %{id: if(id != nil, do: id, else: module), start: {module, :start_link, args}, restart: :permanent, shutdown: :infinity, type: :supervisor, modules: [module]}
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
