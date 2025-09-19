defmodule ChildSpecBuilder do
  def worker(module, args, id) do
    temp_string = nil
    if (id != nil) do
      temp_string = id
    else
      temp_string = module
    end
    %{:id => temp_string, :start => {module, :start_link, args}, :restart => {:permanent}, :shutdown => {:timeout, 5000}, :type => {:worker}, :modules => [module]}
  end
  def supervisor(module, args, id) do
    temp_string = nil
    if (id != nil) do
      temp_string = id
    else
      temp_string = module
    end
    %{:id => temp_string, :start => {module, :start_link, args}, :restart => {:permanent}, :shutdown => {:infinity}, :type => {:supervisor}, :modules => [module]}
  end
  def temp_worker(module, args, id) do
    spec = ChildSpecBuilder.worker(module, args, id)
    spec = Map.put(spec, :restart, {:temporary})
    spec
  end
end