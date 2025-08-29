defmodule TypeSafeChildSpec do
  @moduledoc """
    TypeSafeChildSpec module generated from Haxe

     * Type-safe child specifications for OTP supervisors
     *
     * Provides compile-time checked child specs that generate proper Elixir child specifications.
     * Each method returns a proper child spec map or module reference that Supervisor.start_link expects.
     *
     * ## Usage Example
     *
     * ```haxe
     * var children = [
     *     TypeSafeChildSpec.pubSub("MyApp.PubSub"),
     *     TypeSafeChildSpec.repo("MyApp.Repo", {
     *         database: "myapp_dev",
     *         username: "postgres",
     *         pool_size: 10
     *     }),
     *     TypeSafeChildSpec.endpoint("MyAppWeb.Endpoint"),
     *     TypeSafeChildSpec.telemetry()
     * ];
     *
     * Supervisor.start_link(children, opts);
     * ```
     *
     * ## Generated Elixir Code
     *
     * These methods generate proper child specifications:
     * - Module references: `MyAppWeb.Endpoint`
     * - Tuple specs: `{Phoenix.PubSub, [name: "MyApp.PubSub"]}`
     * - Map specs: `%{id: MyWorker, start: {MyWorker, :start_link, []}}`
  """

  # Static functions
  @doc "Generated from Haxe pubSub"
  def pub_sub(name) do
    {:ModuleWithConfig, "Phoenix.PubSub", [%{:key => "name", :value => name}]}
  end

  @doc "Generated from Haxe repo"
  def repo(module, config \\ nil) do
    if (config != nil) do
      {:ModuleWithConfig, module, config}
    else
      module
    end
  end

  @doc "Generated from Haxe endpoint"
  def endpoint(module) do
    module
  end

  @doc "Generated from Haxe telemetry"
  def telemetry(module) do
    module
  end

  @doc "Generated from Haxe worker"
  def worker(module, args \\ nil) do
    if (args != nil && args.length > 0) do
      {:ModuleWithArgs, module, args}
    else
      module
    end
  end

  @doc "Generated from Haxe supervisor"
  def supervisor(module, args \\ nil, opts \\ nil) do
    temp_array = nil

    if (opts != nil) do
      spec = opts
      id = module
      temp_array = nil
      if (args != nil) do
        temp_array = args
      else
        temp_array = []
      end
      start = %{:module => module, :func => "start_link", :args => temp_array}
      if (spec.type == nil) do
        type = :Supervisor
      end
      spec
    else
      if (args != nil && args.length > 0) do
        {:ModuleWithArgs, module, args}
      else
        module
      end
    end
  end

  @doc "Generated from Haxe taskSupervisor"
  def task_supervisor(name) do
    {:ModuleWithConfig, "Task.Supervisor", [%{:key => "name", :value => name}]}
  end

  @doc "Generated from Haxe registry"
  def registry(name, opts \\ nil) do
    config = [%{:key => "name", :value => name}]
    if (opts != nil) do
      config = config ++ opts
    end
    {:ModuleWithConfig, "Registry", config}
  end

  @doc "Generated from Haxe fromMap"
  def from_map(spec) do
    spec
  end

  @doc "Generated from Haxe simple"
  def simple(module, args \\ nil) do
    if (args != nil && args.length > 0) do
      {:ModuleWithArgs, module, args}
    else
      module
    end
  end

end
