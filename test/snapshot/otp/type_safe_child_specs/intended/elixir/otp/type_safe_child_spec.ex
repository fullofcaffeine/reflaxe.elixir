defmodule TypeSafeChildSpec do
  def pub_sub_unsafe(name) do
    {Phoenix.PubSub, [name: name]}
  end
  def repo_unsafe(module, config) do
    if (not Kernel.is_nil(config)), do: {module, config}, else: module
  end
  def endpoint_unsafe(module) do
    module
  end
  def telemetry_unsafe(module) do
    module
  end
  def worker_unsafe(module, args) do
    if (not Kernel.is_nil(args) and length(args) > 0), do: {module, args}, else: module
  end
  def supervisor_unsafe(module, args, opts) do
    if (not Kernel.is_nil(opts)) do
      spec = opts
      spec = spec |> Map.put(:id, module) |> Map.put(:start, %{:module => module, :func => "start_link", :args => (if (not Kernel.is_nil(args)), do: args, else: [])})
      spec = if (Kernel.is_nil(spec.type)) do
        Map.put(spec, :type, {:supervisor})
      else
        spec
      end
      spec
    else
      if (not Kernel.is_nil(args) and length(args) > 0), do: {module, args}, else: module
    end
  end
  def task_supervisor(name) do
    {Task.Supervisor, [name: name]}
  end
  def registry(name, opts) do
    config = [%{:key => "name", :value => name}]
    config = if (not Kernel.is_nil(opts)), do: config ++ opts, else: config
    {Registry, config}
  end
  def module_ref_unsafe(module) do
    module
  end
  def module_with_config_unsafe(module, config) do
    {module, config}
  end
  def module_with_args_unsafe(module, args) do
    {module, args}
  end
  def from_map(spec) do
    spec
  end
  def simple_unsafe(module, args) do
    if (not Kernel.is_nil(args) and length(args) > 0), do: {module, args}, else: module
  end
end
