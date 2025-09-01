defmodule ChildSpecBuilder do
  def worker(module, args, id) do
    %{:id => (if (id != nil), do: id, else: module), :start => %{:module => module, :func => "start_link", :args => args}, :restart => :permanent, :shutdown => {:Timeout, 5000}, :type => :worker, :modules => [module]}
  end
  def supervisor(module, args, id) do
    %{:id => (if (id != nil), do: id, else: module), :start => %{:module => module, :func => "start_link", :args => args}, :restart => :permanent, :shutdown => :infinity, :type => :supervisor, :modules => [module]}
  end
  def temp_worker(module, args, id) do
    spec = ChildSpecBuilder.worker(module, args, id)
    restart = :temporary
    spec
  end
end