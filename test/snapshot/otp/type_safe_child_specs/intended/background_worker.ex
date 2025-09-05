defmodule BackgroundWorker do
  def new(config) do
    %{:config => config}
  end
  def start_link(_args) do
    %{:_0 => "ok", :_1 => "background_worker_pid"}
  end
end