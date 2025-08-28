defmodule ChildSpecBuilder do
  @moduledoc """
    ChildSpecBuilder module generated from Haxe

     * Helper class for creating child specifications
  """

  # Static functions
  @doc "Generated from Haxe worker"
  def worker(module, args, id \\ nil) do
    temp_string = nil

    if ((id != nil)), do: temp_string = id, else: temp_string = module

    %{type: :worker, start: {%{"module" => module, "func" => "start_link", "args" => args}, :start_link, []}, shutdown: ShutdownType.timeout(5000), restart: :permanent, modules: [module], id: :temp_string}
  end

  @doc "Generated from Haxe supervisor"
  def supervisor(module, args, id \\ nil) do
    temp_string = nil

    if ((id != nil)), do: temp_string = id, else: temp_string = module

    %{type: :supervisor, start: {%{"module" => module, "func" => "start_link", "args" => args}, :start_link, []}, shutdown: :infinity, restart: :permanent, modules: [module], id: :temp_string}
  end

  @doc "Generated from Haxe tempWorker"
  def temp_worker(module, args, id \\ nil) do
    spec = ChildSpecBuilder.worker(module, args, id)

    %{spec | restart: :temporary}

    spec
  end

end
