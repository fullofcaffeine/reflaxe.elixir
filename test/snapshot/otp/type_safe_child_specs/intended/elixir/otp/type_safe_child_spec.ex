defmodule TypeSafeChildSpec do
  def pub_sub(name) do
    {:module_with_config, "Phoenix.PubSub", [%{:key => "name", :value => name}]}
  end
  def repo(module, config) do
    if (config != nil), do: {:module_with_config, module, config}, else: {:module_ref, module}
  end
  def endpoint(module) do
    {:module_ref, module}
  end
  def telemetry(module) do
    {:module_ref, module}
  end
  def worker(module, args) do
    if (args != nil && length(args) > 0), do: {:module_with_args, module, args}, else: {:module_ref, module}
  end
  def supervisor(module, args, opts) do
    if (opts != nil) do
      spec = opts
      id = module
      start = %{:module => module, :func => "start_link", :args => (if (args != nil), do: args, else: [])}
      if (Map.get(spec, :type) == nil) do
        type = {1}
      end
      {:full_spec, spec}
    else
      if (args != nil && length(args) > 0), do: {:module_with_args, module, args}, else: {:module_ref, module}
    end
  end
  def task_supervisor(name) do
    {:module_with_config, "Task.Supervisor", [%{:key => "name", :value => name}]}
  end
  def registry(name, opts) do
    config = [%{:key => "name", :value => name}]
    if (opts != nil) do
      config = config ++ opts
    end
    {:module_with_config, "Registry", config}
  end
  def from_map(spec) do
    {:full_spec, spec}
  end
  def simple(module, args) do
    if (args != nil && length(args) > 0), do: {:module_with_args, module, args}, else: {:module_ref, module}
  end
end