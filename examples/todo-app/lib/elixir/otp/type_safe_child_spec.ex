defmodule TypeSafeChildSpec do
  def pubSub(name) do
    fn name -> {:ModuleWithConfig, "Phoenix.PubSub", [%{:key => "name", :value => name}]} end
  end
  def repo(module, config) do
    fn module, config -> if (config != nil) do
  {:ModuleWithConfig, module, config}
else
  {:ModuleRef, module}
end end
  end
  def endpoint(module) do
    fn module -> {:ModuleRef, module} end
  end
  def telemetry(module) do
    fn module -> {:ModuleRef, module} end
  end
  def worker(module, args) do
    fn module, args -> if (args != nil && args.length > 0) do
  {:ModuleWithArgs, module, args}
else
  {:ModuleRef, module}
end end
  end
  def supervisor(module, args, opts) do
    fn module, args, opts -> if (opts != nil) do
  spec = opts
  id = module
  start = %{:module => module, :func => "start_link", :args => if (args != nil) do
  args
else
  []
end}
  if (spec.type == nil) do
    type = :Supervisor
  end
  {:FullSpec, spec}
else
  if (args != nil && args.length > 0) do
    {:ModuleWithArgs, module, args}
  else
    {:ModuleRef, module}
  end
end end
  end
  def taskSupervisor(name) do
    fn name -> {:ModuleWithConfig, "Task.Supervisor", [%{:key => "name", :value => name}]} end
  end
  def registry(name, opts) do
    fn name, opts -> config = [%{:key => "name", :value => name}]
if (opts != nil) do
  config = config ++ opts
end
{:ModuleWithConfig, "Registry", config} end
  end
  def fromMap(spec) do
    fn spec -> {:FullSpec, spec} end
  end
  def simple(module, args) do
    fn module, args -> if (args != nil && args.length > 0) do
  {:ModuleWithArgs, module, args}
else
  {:ModuleRef, module}
end end
  end
end