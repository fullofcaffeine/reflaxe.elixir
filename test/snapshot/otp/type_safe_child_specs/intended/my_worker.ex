defmodule MyWorker do
  def new(config) do
    %{:config => config}
  end
  def start_link(_args) do
    {"ok", "worker_pid"}
  end
end