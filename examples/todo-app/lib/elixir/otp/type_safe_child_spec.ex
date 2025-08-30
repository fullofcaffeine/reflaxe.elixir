defmodule TypeSafeChildSpec do
  def pubSub() do
    fn name -> {:ModuleWithConfig, "Phoenix.PubSub", [%{:key => "name", :value => name}]} end
  end
  def repo() do
    fn module, config -> if (config != nil) do
  {:ModuleWithConfig, module, config}
else
  {:ModuleRef, module}
end end
  end
  def endpoint() do
    fn module -> {:ModuleRef, module} end
  end
  def telemetry() do
    fn module -> {:ModuleRef, module} end
  end
  def worker() do
    fn module, args -> if (args != nil && args.length > 0) do
  {:ModuleWithArgs, module, args}
else
  {:ModuleRef, module}
end end
  end
  def supervisor() do
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
  def taskSupervisor() do
    fn name -> {:ModuleWithConfig, "Task.Supervisor", [%{:key => "name", :value => name}]} end
  end
  def registry() do
    fn name, opts -> config = [%{:key => "name", :value => name}]
if (opts != nil) do
  config = config ++ opts
end
{:ModuleWithConfig, "Registry", config} end
  end
  def fromMap() do
    fn spec -> {:FullSpec, spec} end
  end
  def simple() do
    fn module, args -> if (args != nil && args.length > 0) do
  {:ModuleWithArgs, module, args}
else
  {:ModuleRef, module}
end end
  end
end