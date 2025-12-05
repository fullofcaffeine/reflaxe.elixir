defmodule TypeSafeChildSpec do
  def pub_sub(_name) do
    {Phoenix.PubSub, [name: name]}
  end
  def repo(module, config) do
    if (not Kernel.is_nil(config)), do: {module, config}, else: module
  end
  def endpoint(module) do
    module
  end
  def telemetry(module) do
    module
  end
  def worker(module, args) do
    if (not Kernel.is_nil(args) and length(args) > 0), do: {module, args}, else: module
  end
  def supervisor(module, args, opts) do
  cond do
    opts != nil ->
      spec = opts
      spec = if Keyword.get(spec, :type) == nil, do: Keyword.put(spec, :type, :supervisor), else: spec
      {:full_spec, spec}
    args != nil and length(args) > 0 -> {:module_with_args, module, args}
    true -> {:module_ref, module}
  end
end

  def task_supervisor(_name) do
    {Task.Supervisor, [name: name]}
  end
  def registry(name, opts) do
    config = [%{:key => "name", :value => name}]
    config = if (not Kernel.is_nil(opts)), do: config ++ opts, else: config
    {Registry, config}
  end
  def from_map(spec) do
    spec
  end
  def simple(module, args) do
    if (not Kernel.is_nil(args) and length(args) > 0), do: {module, args}, else: module
  end
end
