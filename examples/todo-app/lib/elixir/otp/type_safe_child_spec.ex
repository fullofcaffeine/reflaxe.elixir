defmodule TypeSafeChildSpec do
  def pub_sub(name) do
    {:ModuleWithConfig, "Phoenix.PubSub", [%{:key => "name", :value => name}]}
  end
  def repo(module, config) do
    if (config != nil), do: {:ModuleWithConfig, module, config}, else: {:ModuleRef, module}
  end
  def endpoint(module) do
    {:ModuleRef, module}
  end
  def telemetry(module) do
    {:ModuleRef, module}
  end
  def worker(module, args) do
    if (args != nil && args.length > 0), do: {:ModuleWithArgs, module, args}, else: {:ModuleRef, module}
  end
  def supervisor(module, args, opts) do
    if (opts != nil) do
      spec = opts
      id = module
      start = %{:module => module, :func => "start_link", :args => (if (args != nil), do: args, else: [])}
      if (spec.type == nil) do
        type = :Supervisor
      end
      {:FullSpec, spec}
    else
      if (args != nil && args.length > 0), do: {:ModuleWithArgs, module, args}, else: {:ModuleRef, module}
    end
  end
  def task_supervisor(name) do
    {:ModuleWithConfig, "Task.Supervisor", [%{:key => "name", :value => name}]}
  end
  def registry(name, opts) do
    config = [%{:key => "name", :value => name}]
    if (opts != nil) do
      config = config ++ opts
    end
    {:ModuleWithConfig, "Registry", config}
  end
  def from_map(spec) do
    {:FullSpec, spec}
  end
  def simple(module, args) do
    if (args != nil && args.length > 0), do: {:ModuleWithArgs, module, args}, else: {:ModuleRef, module}
  end
end