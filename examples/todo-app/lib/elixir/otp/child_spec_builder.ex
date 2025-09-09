defmodule ChildSpecBuilder do
  def worker(module, args, id) do
    %{:id => (if (id != nil), do: id, else: module), :start => {module, :start_link, args}, :restart => {0}, :shutdown => {:Timeout, 5000}, :type => {0}, :modules => [module]}
  end
  def supervisor(module, args, id) do
    %{:id => (if (id != nil), do: id, else: module), :start => {module, :start_link, args}, :restart => {0}, :shutdown => {2}, :type => {1}, :modules => [module]}
  end
  def temp_worker(module, args, id) do
    spec = worker(module, args, id)
    restart = {1}
    spec
  end
end