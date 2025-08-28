defmodule ChildSpecBuilder do
  @moduledoc """
    ChildSpecBuilder module generated from Haxe

     * Helper class for creating child specifications
  """

  # Static functions
  @doc "Generated from Haxe worker"
  def worker(module, args, id \\ nil) do
    temp_string = nil

    temp_string = nil

    if ((id != nil)), do: temp_string = id, else: temp_string = module

    %{id: if(id != nil, do: id, else: module), start: {module, :start_link, args}, restart: :permanent, shutdown: ShutdownType.timeout(5000), type: :worker, modules: [module]}
  end

  @doc "Generated from Haxe supervisor"
  def supervisor(module, args, id \\ nil) do
    temp_string = nil

    if ((id != nil)), do: temp_string = id, else: temp_string = module

    %{id: if(id != nil, do: id, else: module), start: {module, :start_link, args}, restart: :permanent, shutdown: :infinity, type: :supervisor, modules: [module]}
  end

  @doc "Generated from Haxe tempWorker"
  def temp_worker(module, args, id \\ nil) do
    spec = ChildSpecBuilder.worker(module, args, id)

    %{spec | restart: :temporary}

    spec
  end

end
