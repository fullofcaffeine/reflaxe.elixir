defmodule ChildSpecBuilder do
  def worker(module, args, id) do
    %{:id => if (id != nil), do: id, else: module, :start => %{:module => module, :func => "start_link", :args => args}, :restart => :Permanent, :shutdown => {:Timeout, 5000}, :type => :Worker, :modules => [module]}
  end
  def supervisor(module, args, id) do
    %{:id => if (id != nil), do: id, else: module, :start => %{:module => module, :func => "start_link", :args => args}, :restart => :Permanent, :shutdown => :Infinity, :type => :Supervisor, :modules => [module]}
  end
  def tempWorker(module, args, id) do
    spec = ChildSpecBuilder.worker(module, args, id)
    restart = :Temporary
    spec
  end
end