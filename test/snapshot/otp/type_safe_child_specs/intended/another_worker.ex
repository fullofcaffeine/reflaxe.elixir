defmodule AnotherWorker do
  def new(config) do
    %{:config => config}
  end
  def start_link(_args) do
    {"ok", "another_worker_pid"}
  end
end