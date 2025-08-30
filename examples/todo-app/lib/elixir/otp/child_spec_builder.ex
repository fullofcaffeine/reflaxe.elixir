defmodule ChildSpecBuilder do
  def worker() do
    fn module, args, id -> %{:id => if (id != nil) do
  id
else
  module
end, :start => %{:module => module, :func => "start_link", :args => args}, :restart => :Permanent, :shutdown => {:Timeout, 5000}, :type => :Worker, :modules => [module]} end
  end
  def supervisor() do
    fn module, args, id -> %{:id => if (id != nil) do
  id
else
  module
end, :start => %{:module => module, :func => "start_link", :args => args}, :restart => :Permanent, :shutdown => :Infinity, :type => :Supervisor, :modules => [module]} end
  end
  def tempWorker() do
    fn module, args, id -> spec = ChildSpecBuilder.worker(module, args, id)
restart = :Temporary
spec end
  end
end