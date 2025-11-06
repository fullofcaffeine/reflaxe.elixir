defmodule ChildSpecBuilder do
  def worker(module, args, id) do
    %{:id => (if (not Kernel.is_nil(id)), do: id, else: module), :start => {module, :start_link, args}, :restart => {:permanent}, :shutdown => {:timeout, 5000}, :type => {:worker}, :modules => [module]}
  end
  def supervisor(module, args, id) do
    %{:id => (if (not Kernel.is_nil(id)), do: id, else: module), :start => {module, :start_link, args}, :restart => {:permanent}, :shutdown => {:infinity}, :type => {:supervisor}, :modules => [module]}
  end
  def temp_worker(module, args, id) do
    spec = worker(module, args, id)
    spec = Map.put(spec, "restart", {:temporary})
    spec
  end
end
