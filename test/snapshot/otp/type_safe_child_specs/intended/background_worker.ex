defmodule BackgroundWorker do
  def new(config) do
    %{:config => config}
  end
  def start_link(_args) do
    {"ok", "background_worker_pid"}
  end
end